backup
==========================

A small and simple backupscript which makes incremental recursive backups of directories from local and remote mashines, saving them in ordered human readable timestamped directories using rsync, locks and hardlinks. This script makes a lot of checks and tests to prevent errors. All preferences can be controlled with one configurationfile.

**enviroment, depencies, installation, interface, usage...**

**Enviroment:**
This script has only been tested on a gentoo linux x64 machine with perl5. 

I will add details later...

**Depencies:** 
- perlmodules Data::Dumper, File::Path and JSON are needed
- the commandline programs "cp" and "rsync" are needed
- on each backup-target should run an rsync-server (on windows, you can run "deltacopy" which is a free but slow rsync-server)
- you need to setup ssh key authentication on each backup-target server
- cron-server to run this script through a cronjob

- I will add details later...

**Installation:**
You should create a directory and put that script, along with its configurationfile into that directory.

I will add details later...

**Interface, usage:**
Command-line based. This script is executed from the command-line. I suggest using a cronjob to run it. 
All preferences like backup-targets, number of backups etc need to be stored in a configurationfile, called backup.json ... see backup.json.example for details

I will add more details later...
