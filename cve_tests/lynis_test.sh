#!/bin/bash
EXITCODE=0

cd /opt/bin/lynis
INCLUDEDIR="/opt/include/lynis" /opt/bin/lynis/lynis -Q -c --profile "/opt/bin/lynis/docker-alpine.prf" audit system < /dev/null
if [ $? -ne 0 ]
then
  EXITCODE=$((EXITCODE+1))
fi
cd - > /dev/null

exit $EXITCODE
