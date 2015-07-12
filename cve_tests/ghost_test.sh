#!/bin/bash
EXITCODE=0

# CVE-2015-0235
# Alpine is musl-libc based and was therefore never vulnerable to Ghost.
echo -e "CVE-2015-0235 (ghost): \033[92mnot applicable\033[39m"

exit $EXITCODE
