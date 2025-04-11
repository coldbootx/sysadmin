#!/usr/bin/ksh93
###############################################################################################
#### A simple admin tool for debian base system script.
#### This will fix any broke or missing dependencies, update package list, upgrade packages,
#### upgrade dependencies, then it will run a full clean up!
#### This program needs to be ran as sudo after script is complete it drops sudo privileges!
###############################################################################################

#### Set Debug Mode
# set -x

function displaymsg {
  print "
Program: update.ksh
Author: William Butler (william_butler76@yahoo.com)
License: GNU GPL (version 3, or any later version).
"
}

displaymsg

# Exit
exit ${?}