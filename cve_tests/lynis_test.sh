#!/bin/bash
EXITCODE=0

/opt/bin/lynis/lynis audit system -Q

exit $EXITCODE
