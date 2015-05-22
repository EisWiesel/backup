#!/usr/bin/perl

use strict;
use utf8;
use warnings;

use Data::Dumper;
use File::Path;
use JSON;

binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

#################################################
# locking
if ( -e "./backup.lock" ) {
	die( "lockfile already exists\n" );
} else {
	open(my $fh, '>', "backup.lock") or die( $! );
	close( $fh );
}


#################################################
# read config
local $/;
open( my $fh, '<', 'backup.json' ) or die( "json config-file could not be read!\n" );
my $json_text   = <$fh>;
close( $fh );
my $json_config = decode_json( $json_text );
print Data::Dumper::Dumper( $json_config );
#################################################
# check config
die ( "no backup_path!\n" ) 
	if ( !exists( $json_config->{'backup_path'} ) || exists( $json_config->{'backup_path'} ) && !-d $json_config->{'backup_path'} );
die ( "backup_path must end with slash!\n" ) 
	if ( substr( $json_config->{'backup_path'}, -1) ne '/' );
die ( "no backup_targets found!\n" ) 
	if ( !exists( $json_config->{'backup_targets'} ) || exists( $json_config->{'backup_targets'} ) && scalar( @{ $json_config->{'backup_targets'} } ) < 1 );

foreach my $backup_target ( @{ $json_config->{'backup_targets'} } ) {
	die( "no name found!\n" )
		if ( !exists( $backup_target->{'name'} ) );
	die( "no keep found!\n" )
		if ( !exists( $backup_target->{'keep'} ) );
	die( "no backup inpout/output!\n" )
		if ( !exists( $backup_target->{'backup'} ) || scalar( @{ $backup_target->{'backup'} } ) < 1 );	
	foreach my $inout ( @{ $backup_target->{'backup'} } ) {
		die ( "incorrect input/output pair found in '" . $backup_target->{'name'} . "'!\n" )
			if ( !exists( $inout->{'input'} ) || !exists( $inout->{'output'} ) );
	}
}
#################################################
# start backup

foreach my $backup_target ( @{ $json_config->{'backup_targets'} } ) {

	if ( !-d $json_config->{'backup_path'} . $backup_target->{'name'} ) {
		mkdir( $json_config->{'backup_path'} . $backup_target->{'name'} ) or die( $! );
	}

	my $last_backupdir = get_last_backup( $json_config->{'backup_path'} . $backup_target->{'name'} );

	my $timestamp = get_timestamp();

	if ( !defined( $last_backupdir ) ) {
		
		mkdir( $json_config->{'backup_path'} . $backup_target->{'name'} . "/" . $timestamp ) or die( $! );
		make_backup( 
			$json_config->{'backup_path'}, 
			$backup_target->{'name'}, 
			$timestamp, 
			$backup_target->{'backup'}
		);
	} else {

		make_copy(
			$last_backupdir,
			$json_config->{'backup_path'} . $backup_target->{'name'} . "/" . $timestamp
		);
		
		make_backup( 
			$json_config->{'backup_path'}, 
			$backup_target->{'name'}, 
			$timestamp, 
			$backup_target->{'backup'}
		);
	}

	rotate_backups(
		$json_config->{'backup_path'} . $backup_target->{'name'},
		$backup_target->{'keep'}
	);

}

#################################################
# unlock
unlink( './backup.lock' ) or die( $! );

print "evrything done :)\n";


#################################################
# subs
sub get_last_backup {
	my $backup_path = shift;
	
	opendir( my $fh, $backup_path ) || die( "cannot open directory " . $backup_path . "\n" ); 
	my @backup_dirs = readdir( $fh ); 
	closedir( $fh );
	foreach my $backup_dir ( reverse( sort( @backup_dirs ) ) ) {
		if ( -d $backup_path . "/" . $backup_dir && $backup_dir =~ m/^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}$/ ) {
			print "last backupdir: '" . $backup_path . "/" . $backup_dir . "'\n";
			return $backup_path . "/" . $backup_dir;
		}
	}
	return undef;
}

sub make_backup {
	my $backup_path      = shift;
	my $backup_name      = shift;
	my $backup_timestamp = shift;
	my $backup_dirs      = shift;

	if ( -e $backup_path . $backup_name . "/" . $backup_timestamp . ".lock" ) {
		die( "lockfile '" . $backup_path . $backup_name . "/" . $backup_timestamp . ".lock' already exists\n" );
	} else {
		open( my $fh, '>', $backup_path . $backup_name . "/" . $backup_timestamp . ".lock" ) or die( $! );
		close( $fh );
	}
	
	foreach my $backup ( @{ $backup_dirs } ) {
		if ( $backup->{'output'} ne '' ) {
			mkdir( $backup_path . $backup_name . "/" . $backup_timestamp . "/" . $backup->{'output'} )
				or die( $! );
		}
		
		my $input_dir  = $backup->{'input'};
		my $output_dir = $backup_path . $backup_name . "/" . $backup_timestamp . "/" . $backup->{'output'};
		
		`rsync --archive --delete $input_dir $output_dir`;
		
		print "rsync on '" . $output_dir . "' for '" . $input_dir . "' done\n";
	}
	
	unlink( $backup_path . $backup_name . "/" . $backup_timestamp . ".lock" );
}

sub get_timestamp {
	
	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( time() );
	$mon  += 1;
	$year += 1900;
	
	return sprintf( "%04d-%02d-%02d_%02d-%02d-%02d", $year, $mon, $mday, $hour, $min, $sec );
}

sub make_copy {
	my $source_dir      = shift;
	my $destination_dir = shift;
	
	if ( -e $destination_dir . ".lock" ) {
		die( "lockfile '" . $destination_dir . ".lock' already exists\n" );
	} else {
		open( my $fh, '>', $destination_dir . ".lock" ) or die( $! );
		close( $fh );
	}
	
	`cp --archive --link $source_dir $destination_dir`;

	unlink( $destination_dir . ".lock" );

	print "made copy of '" . $source_dir . "' to '" . $destination_dir . "'\n";
}

sub rotate_backups {
	my $backups_path = shift;
	my $keep         = shift;
	
	if ( -e $backups_path . "/delete.lock" ) {
		die( "lockfile '" . $backups_path . "/delete.lock' already exists\n" );
	} else {
		open( my $fh, '>', $backups_path . "/delete.lock" ) or die( $! );
		close( $fh );
	}
	
	opendir( my $fh, $backups_path ) || die( "cannot open directory " . $backups_path . "\n" ); 
	my @backup_dirs = readdir( $fh ); 
	closedir( $fh );
	
	my $backup_cntr = 0;
	
	foreach my $backup_dir ( reverse( sort( @backup_dirs ) ) ) {
		if ( -d $backups_path . "/" . $backup_dir && $backup_dir =~ m/^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}$/ ) {
			$backup_cntr++;
		}
		if ( $backup_cntr > $keep && -d $backups_path . "/" . $backup_dir && $backup_dir =~ m/^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}$/ ) {
			rmtree( $backups_path . "/" . $backup_dir );
			print "rotated '" . $backups_path . "/" . $backup_dir . "'\n";
		}
	}
	
	unlink( $backups_path . "/delete.lock" );
}
__END__
