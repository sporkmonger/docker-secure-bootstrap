#!/bin/bash
EXITCODE=0

cd /opt/bin/lynis
/opt/bin/lynis/lynis -Q -c audit system < /dev/null
if [ $? -ne 0 ]
then
  EXITCODE=$((EXITCODE+1))
fi
cd - > /dev/null

exit $EXITCODE
