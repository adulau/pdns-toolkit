#!/bin/sh
#
# A simple feeder using dnscap input
#

./dnscap -T -s r -ieth1 -g 2>&1 >/dev/null |  perl pdns-feeder.pl
