#!/bin/bash
EXITCODE=0

# These version checks are far from truly reliable.
# Currently only testing them against Alpine, CoreOS, & OS X.
CURL_VERSION=$(`which curl` -V 2>&1 | grep -o -m 1 -e "curl [0-9]\{0,3\}\.[0-9]\{0,3\}\.[0-9]\{0,3\}" | grep -o -m 1 -e "[0-9]\{0,3\}\.[0-9]\{0,3\}\.[0-9]\{0,3\}")
WGET_VERSION=$(`which wget` -V 2>&1 | grep -o -m 1 -e "[wWbB][gu][es][ty][bBox]* v*[0-9\.]\{1,9\}[^- ]*" | grep -o -m 1 -e "[0-9\.]\{1,9\}[^- ]*")
OPENSSL_VERSION=$(`which openssl` version 2>&1 | grep -o -m 1 -e "^OpenSSL [0-9]\{0,3\}\.[0-9]\{0,3\}\.[0-9]\{0,3\}[^- ]*" | grep -o -m 1 -e "[0-9]\{0,3\}\.[0-9]\{0,3\}\.[0-9]\{0,3\}[^- ]*")
OPENSSL_LIB_VERSION=$(`which openssl` version 2>&1 | grep -o -m 1 -e "Library: OpenSSL [0-9]\{0,3\}\.[0-9]\{0,3\}\.[0-9]\{0,3\}[^- ]*" | grep -o -m 1 -e "[0-9]\{0,3\}\.[0-9]\{0,3\}\.[0-9]\{0,3\}[^- ]*")
PRUNED_APK_CACHE=0
if [[ (`apk version 2>&1` =~ "No such file or directory") ]]; then
  apk update > /dev/null
  PRUNED_APK_CACHE=1
fi
LIBCRYPTO_VERSION=$(apk version 2>&1 | grep -o -m 1 -e "libcrypto[^-]*-[0-9]\{0,3\}\.[0-9]\{0,3\}\.[0-9]\{0,3\}[^- ]*"  | grep -o -m 1 -e "[0-9]\{0,3\}\.[0-9]\{0,3\}\.[0-9]\{0,3\}[^- ]*")
LIBSSL_VERSION=$(apk version 2>&1 | grep -o -m 1 -e "libssl[^-]*-[0-9]\{0,3\}\.[0-9]\{0,3\}\.[0-9]\{0,3\}[^- ]*"  | grep -o -m 1 -e "[0-9]\{0,3\}\.[0-9]\{0,3\}\.[0-9]\{0,3\}[^- ]*")
if [[ (PRUNED_APK_CACHE -eq 1) ]]; then
  rm -rf /var/cache/apk/*
fi
# Test libssl and libcrypto even if openssl isn't installed
# The libssl and libcrypto libraries will always have the
# same version number, so the extra elif is really just
# defensive coding.
if [[ ("$OPENSSL_VERSION" == "") ]]; then
  if [[ ("$OPENSSL_LIB_VERSION" != "") ]]; then
    OPENSSL_VERSION="$OPENSSL_LIB_VERSION"
  elif [[ ("$LIBSSL_VERSION" != "") ]]; then
    OPENSSL_VERSION="$LIBSSL_VERSION"
  elif [[ ("$LIBCRYPTO_VERSION" != "") ]]; then
    OPENSSL_VERSION="$LIBCRYPTO_VERSION"
  fi
else
  # OpenSSL is present, so now make sure we don't have anything out of sync.
  if [[ ("$OPENSSL_LIB_VERSION" != "") && ("$OPENSSL_VERSION" != "$OPENSSL_LIB_VERSION") ]]; then
    echo -e "\033[91mopenssl and library versions differ ($OPENSSL_VERSION/$OPENSSL_LIB_VERSION) \033[39m"
    EXITCODE=1
  elif [[ ("$LIBCRYPTO_VERSION" != "") && ("$OPENSSL_VERSION" != "$LIBCRYPTO_VERSION") ]]; then
    echo -e "\033[91mopenssl and libcrypto versions differ ($OPENSSL_VERSION/$LIBCRYPTO_VERSION) \033[39m"
    EXITCODE=1
  elif [[ ("$LIBSSL_VERSION" != "") && ("$OPENSSL_VERSION" != "$LIBSSL_VERSION") ]]; then
    echo -e "\033[91mopenssl and libssl versions differ ($OPENSSL_VERSION/$LIBSSL_VERSION) \033[39m"
    EXITCODE=1
  fi
fi

if [[ ("$OPENSSL_VERSION" == "") ]]; then
  apk update
  apk version
  echo "$OPENSSL_VERSION $OPENSSL_LIB_VERSION $LIBSSL_VERSION $LIBCRYPTO_VERSION"
  echo -e "\033[91mno openssl version number to check against\033[39m"
  exit 1
fi

if [ ! -z $CURL_VERSION ]; then
  OPENSSL_VULNERABILITY_LIST=`curl -sS https://www.openssl.org/news/vulnerabilities.html`
elif [ ! -z $WGET_VERSION ]; then
  OPENSSL_VULNERABILITY_LIST=`wget -q -O - http://www.openssl.org/news/vulnerabilities.html`
else
  echo -e "\033[91mneither curl nor wget is installed\033[39m"
  exit 1
fi
if [[ ! "$OPENSSL_VULNERABILITY_LIST" =~ "OpenSSL vulnerabilities" ]]; then
  echo -e "\033[91munexpected response from http://www.openssl.org/news/vulnerabilities.html\033[39m"
  exit 1
fi

echo "$OPENSSL_VULNERABILITY_LIST" | gawk -v RS='<dt>' '
  BEGIN { ORS="\t" }
  # Print the CVE number
  i = match($0, /(CVE-[[:digit:]]+-[[:digit:]]+)/, cap) {
    print cap[1]
  } !i { print "" }
  i = match($0, /<\/b>([[:digit:]]+[tnr][hd] .+ [[:digit:]]+)<p><\/dt>/, cap) {
    print cap[1]
  } !i { print "" }
  i = match($0, /<description>[[:space:]]*(.+)[[:space:]]*<\/description>/, cap) {
    rawdesc = cap[1];
    gsub(/[[:space:]]+/, " ", rawdesc);
    print rawdesc
  } !i { print "" }
  i = match(substr($0, offset), /Fixed in OpenSSL[[:space:]]+(0\.9\.6[a-zA-Z]{0,2})[[:space:]]+\(Affected[[:space:]]+(([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+[a-zA-Z]{0,2}[[:space:]]*,?[[:space:]]*)+)\)/, cap) {
    print cap[1];
    print cap[2]
  } !i { print ""; print "" }
  i = match(substr($0, offset), /Fixed in OpenSSL[[:space:]]+(0\.9\.7[a-zA-Z]{0,2})[[:space:]]+\(Affected[[:space:]]+(([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+[a-zA-Z]{0,2}[[:space:]]*,?[[:space:]]*)+)\)/, cap) {
    print cap[1];
    print cap[2]
  } !i { print ""; print "" }
  i = match(substr($0, offset), /Fixed in OpenSSL[[:space:]]+(0\.9\.8[a-zA-Z]{0,2})[[:space:]]+\(Affected[[:space:]]+(([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+[a-zA-Z]{0,2}[[:space:]]*,?[[:space:]]*)+)\)/, cap) {
    print cap[1];
    print cap[2]
  } !i { print ""; print "" }
  i = match(substr($0, offset), /Fixed in OpenSSL[[:space:]]+(0\.9\.9[a-zA-Z]{0,2})[[:space:]]+\(Affected[[:space:]]+(([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+[a-zA-Z]{0,2}[[:space:]]*,?[[:space:]]*)+)\)/, cap) {
    print cap[1];
    print cap[2]
  } !i { print ""; print "" }
  i = match(substr($0, offset), /Fixed in OpenSSL[[:space:]]+(1\.0\.0[a-zA-Z]{0,2})[[:space:]]+\(Affected[[:space:]]+(([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+[a-zA-Z]{0,2}[[:space:]]*,?[[:space:]]*)+)\)/, cap) {
    print cap[1];
    print cap[2]
  } !i { print ""; print "" }
  i = match(substr($0, offset), /Fixed in OpenSSL[[:space:]]+(1\.0\.1[a-zA-Z]{0,2})[[:space:]]+\(Affected[[:space:]]+(([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+[a-zA-Z]{0,2}[[:space:]]*,?[[:space:]]*)+)\)/, cap) {
    print cap[1];
    print cap[2]
  } !i { print ""; print "" }
  i = match(substr($0, offset), /Fixed in OpenSSL[[:space:]]+(1\.0\.2[a-zA-Z]{0,2})[[:space:]]+\(Affected[[:space:]]+(([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+[a-zA-Z]{0,2}[[:space:]]*,?[[:space:]]*)+)\)/, cap) {
    print cap[1];
    print cap[2]
  } !i { print ""; print "" }
  i = match(substr($0, offset), /Fixed in OpenSSL[[:space:]]+(1\.0\.3[a-zA-Z]{0,2})[[:space:]]+\(Affected[[:space:]]+(([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+[a-zA-Z]{0,2}[[:space:]]*,?[[:space:]]*)+)\)/, cap) {
    print cap[1];
    print cap[2]
  } !i { print ""; print "" }
  { printf "\n" }
' | gawk -v OPENSSL_VERSION="$OPENSSL_VERSION" '
  BEGIN {
    RS="\n";
    FS="\t";
    vulnerable = 0
  }
  {
    if ($1) {
      fixed_in = "";
      affected_in = ""
      if (OPENSSL_VERSION ~ /0\.9\.6/) {
        fixed_in = $4;
        affected_in = $5
      } else if (OPENSSL_VERSION ~ /0\.9\.7/) {
        fixed_in = $6;
        affected_in = $7
      } else if (OPENSSL_VERSION ~ /0\.9\.8/) {
        fixed_in = $8;
        affected_in = $9
      } else if (OPENSSL_VERSION ~ /0\.9\.9/) {
        fixed_in = $10;
        affected_in = $11
      } else if (OPENSSL_VERSION ~ /1\.0\.0/) {
        fixed_in = $12;
        affected_in = $13
      } else if (OPENSSL_VERSION ~ /1\.0\.1/) {
        fixed_in = $14;
        affected_in = $15
      } else if (OPENSSL_VERSION ~ /1\.0\.2/) {
        fixed_in = $16;
        affected_in = $17
      } else if (OPENSSL_VERSION ~ /1\.0\.3/) {
        fixed_in = $18;
        affected_in = $19
      }
      if (fixed_in == OPENSSL_VERSION) {
        printf $1;
        printf ": ";
        print "\033[92mnot vulnerable (fixed)\033[39m"
      } else if (fixed_in && affected_in) {
        if (affected_in ~ OPENSSL_VERSION) {
          vulnerable++;
          printf $1;
          printf ": ";
          print "\033[91mvulnerable\033[39m"
          printf "\t"
          print $2
          printf "\t"
          print $3
        } else {
          printf $1;
          printf ": ";
          print "\033[92mnot vulnerable (unaffected)\033[39m"
        }
      } else {
        printf $1;
        printf ": ";
        print "\033[92mnot vulnerable (unaffected)\033[39m"
      }
    }
  }
  END {
    if (vulnerable) {
      exit vulnerable
    }
  }
'
if [ $? -ne 0 ]
then
  echo -e "OpenSSL Version: \033[91m$OPENSSL_VERSION\033[39m"
  EXITCODE=$((EXITCODE+1))
fi

exit $EXITCODE
