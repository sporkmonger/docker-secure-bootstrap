#!/bin/bash
EXITCODE=0

cd /opt/bin/lynis
/opt/bin/lynis/lynis -Q audit system < /dev/null
if [ $? -ne 0 ]
then
  EXITCODE=$((EXITCODE+1))
fi
cd -

exit $EXITCODE
