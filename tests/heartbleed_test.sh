#!/bin/bash
EXITCODE=0

# CVE-2014-0160
# These version checks are far from truly reliable.
LIBCRYPTO_VERSION=$(apk info libcrypto1.0 2>&1 | grep -o -m 1 -e "\d\.\d\.\d[^- ]*")
LIBSSL_VERSION=$(apk info libssl1.0 2>&1 | grep -o -m 1 -e "\d\.\d\.\d[^- ]*")
OPENSSL_VERSION=$(`which openssl` version 2>&1 | grep -o -m 1 -e "\d\.\d\.\d[^- ]*")

CVE20140160_LIBCRYPTO=$(echo $LIBCRYPTO_VERSION 2>&1 | grep "1\.0\.1[ abcdef]" | wc -l)

echo -n "CVE-2014-0160 (heartbleed libcrypto): "
if [ ! -z $LIBCRYPTO_VERSION ]; then
  if [ $CVE20140160_LIBCRYPTO -gt 0 ]; then
    echo -e "\033[91mVULNERABLE\033[39m"
    EXITCODE=$((EXITCODE+1))
  else
    echo -e "\033[92mnot vulnerable\033[39m"
  fi
else
  echo -e "\033[92mnot applicable\033[39m"
fi

CVE20140160_LIBSSL=$(echo $LIBSSL_VERSION 2>&1 | grep "1\.0\.1[ abcdef]" | wc -l)

echo -n "CVE-2014-0160 (heartbleed libssl): "
if [ ! -z $LIBSSL_VERSION ]; then
  if [ $CVE20140160_LIBSSL -gt 0 ]; then
    echo -e "\033[91mVULNERABLE\033[39m"
    EXITCODE=$((EXITCODE+1))
  else
    echo -e "\033[92mnot vulnerable\033[39m"
  fi
else
  echo -e "\033[92mnot applicable\033[39m"
fi

CVE20140160_OPENSSL=$(echo $OPENSSL_VERSION 2>&1 | grep "1\.0\.1[ abcdef]" | wc -l)

echo -n "CVE-2014-0160 (heartbleed openssl): "
if [ ! -z $OPENSSL_VERSION ]; then
  if [ $CVE20140160_OPENSSL -gt 0 ]; then
    echo -e "\033[91mVULNERABLE\033[39m"
    EXITCODE=$((EXITCODE+1))
  else
    echo -e "\033[92mnot vulnerable\033[39m"
  fi
else
  echo -e "\033[92mnot applicable\033[39m"
fi

exit $EXITCODE
