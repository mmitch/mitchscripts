#!/bin/bash
#
# simple X notification framework
# framework startup
#
# 2009 (C) by Christian Garbs <mitch@cgarbs.de>
# licensed under GNU GPL v2
#

# remove old instances
killall notify.sh mailnotify.sh 

# startup
/home/mitch/git/mitchscripts/bash/notify.sh &
/home/mitch/git/mitchscripts/bash/mailnotify.sh &

