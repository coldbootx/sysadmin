################################################################
#### 
#### Program:
#### sysadmin.ksh
#### 
#### Author/Contact:
#### William Butler (coldboot@mailfence.com)
#### 
#### License:
#### MIT License
#### 
#### Description:
#### This is a simple system admin tool writen in Korn shell for
#### the OpenBSD systems.
#### 
#### Assumptions:
#### The system admin tool assumes you use on an OpenBSD system.
#### 
#### Dependencies: 
#### A OpenBSD system
#### 
#### Products:
#### The system admin tool provides easy user managment: 
#### List all users, UIDs, and shells. Add, del, and lock 
#### user account.
#### List running services. Start, stop, and restart services.
#### List open ports with netcat. Run a simple ping sweep.
#### Read authlog, secure, and pflog logs are piped to less.
#### Run password generator and save to logfile.
#### Run full system update including: syspatch, fw_update, 
#### and all packages. No ports update in this release.
####
#### Configured Usage:
#### The system admin tool should be run with doas.
#### 
################################################################
