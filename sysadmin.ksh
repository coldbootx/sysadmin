#!/usr/bin/ksh93
###############################################################################################
#### A simple admin tool for debian base system script.
###############################################################################################

#### Set Debug Mode
# set -x

function displaymsg {
  print "
Program: sysadmin.ksh
Author: William Butler (william_butler76@yahoo.com)
License: GNU GPL (version 3, or any later version).
"
}

displaymsg

# Exit
exit ${?}
