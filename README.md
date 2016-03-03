backup
==========================

A small and simple backupscript which makes incremental recursive backups of directories from local and remote mashines, saving them in ordered human readable timestamped directories using rsync, locks and hardlinks. This script makes a lot of checks and tests to prevent errors. All preferences can be controlled with one configurationfile.

Because its using hardlinks, the incremental backup which comes next to the first full backup will only take space of changed files. 

**enviroment, depencies, installation, interface, usage...**

**Enviroment:**
This script has only been tested on a gentoo linux x64 machine with perl5 and ext3/ext4 filesystem

**Depencies on backup server**
* perlmodules Data::Dumper, File::Path and JSON are needed
* the commandline programs "cp" and "rsync" are needed
  * cp and filesystem must support the hardlink-switch "--link"
* you need to setup ssh key authentication for each backup-target on your backupserver

**Depencies on backup client**
* rsync-server on each backup client 
* on windows, you can run "deltacopy" which is a free and easy to use rsync-server (cygwin port)
  * I recommend using the windows internal backup function to create a local backup first, then using this script to backup it on the backup server. This way, you dont have to mess with links and too long filenames.


**Installation:**
You should create a directory and put that script, along with its configurationfile into that directory. The configfile must have the filename "backup.json" and has to be in the same directory as the backupscript. 

I will add details later...

**Interface, usage:**
Command-line based. This script is executed from the command-line. I suggest using a cronjob to run it. 
All preferences like backup-targets, number of backups etc need to be stored in a configurationfile, called backup.json ... see backup.json.example for details

Format of the configfile:
```json
{
	"backup_path":"/path/to/a/local/place/",
	"backup_targets":[
		{
			"name":"name_for_backup_of_local_mashine",
			"keep":5,
			"rsync_options":"--archive --delete",
			"backup":[
				{
					"input":"/etc",
					"output":""
				},
				{
					"input":"/var",
					"output":""
				}
			]
		},
                {
			"name":"name_for_backup_of_remote_mashine",
			"keep":5,
			"rsync_options":"--archive --delete",
			"backup":[
				{
					"input":"root@192.168.0.100:/etc",
					"output":""
				}
			]
		}
	]
}
```

Explanation:
- backup_path -> path where this script should be and where to store all the backups
- backup_targets -> an json array with the backup-targets
- name -> name for the backup, each backup will be saved with this name
- keep -> number of max backups before they will be rotated
- rsync_options -> options applied to rsync when syncing to destination
- backup -> json array which holds backupsources
- input -> source of the backup, this will be passed as parameter to rsync
- output -> leave empty... or write a different name for this backupsource if you want so

I will add more details later...
