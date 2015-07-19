FROM alpine:latest
MAINTAINER Bob Aman <bob@sporkmonger.com>

RUN apk add --update bash gawk wget && \
  apk upgrade && \
  apk version && \
  rm -rf /var/cache/apk/*

# I just can't deal with terminals that don't have pretty colors.
ENV PS1="\[\033[01;32m\]\u@\h\[\033[01;34m\] \w \$\[\033[00m\] " \
  TERM="xterm-color"

RUN echo -e "# Not that this is a real concern, but protect single user mode\nsu:S:wait:/sbin/sulogin" >> /etc/inittab

RUN mkdir -p /opt/bin /opt/include /opt/src /opt/bin/cve_tests
# Uses key ID 2CCB36ADFC5849A7 / netblue (firejail key) <netblue30@yahoo.com>
# for code signature, tarball hashed w/ SHA256
COPY ./firejail /opt/src/firejail
RUN cd /opt/src/firejail && \
  tar -xjvf firejail-0.9.26.tar.bz2 && \
  cd firejail-0.9.26 && \
  apk add --update make gcc g++ && \
  ./configure && \
  make &&
  make install && \
  apk del make gcc g++ && \
  rm -rf /var/cache/apk/*
COPY ./cve_tests /opt/bin/cve_tests
COPY ./cveck /opt/bin/cveck
COPY ./lynis /opt/bin/lynis
COPY ./lynis/include /opt/include/lynis
RUN chmod a+x /opt/bin/cve_tests/*_test.sh && chmod a+x /opt/bin/cveck
RUN /opt/bin/cveck

CMD [ "/bin/bash" ]
