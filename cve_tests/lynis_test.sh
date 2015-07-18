#!/bin/bash
EXITCODE=0

cd /opt/bin/lynis && lynis -Q audit system < /dev/null && cd -

exit $EXITCODE
