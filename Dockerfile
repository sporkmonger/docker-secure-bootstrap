FROM alpine:latest
MAINTAINER Bob Aman <bob@sporkmonger.com>

RUN apk add --update bash gawk wget fakeroot sudo logrotate clamav-scanner clamav-libunrar freshclam && \
  apk upgrade && \
  apk version && \
  rm -rf /var/cache/apk/*

# I just can't deal with terminals that don't have pretty colors.
ENV PS1="\[\033[01;32m\]\u@\h\[\033[01;34m\] \w \$\[\033[00m\] " \
  TERM="xterm-color"

RUN echo -e "# Not that this is a real concern, but protect single user mode\nsu:S:wait:/sbin/sulogin" >> /etc/inittab

RUN mkdir -p /opt/bin /opt/src

COPY ./freshclam.conf /etc/clamav/freshclam.conf
COPY ./clamd.conf /etc/clamav/clamd.conf
COPY ./lynis /opt/bin/lynis
RUN /usr/bin/freshclam --quiet && \
  /usr/bin/sudo /usr/bin/clamscan -r -i --exclude-dir=/sys --exclude-dir=/proc /
RUN /opt/bin/lynis/lynis -Q -c --profile "/opt/bin/lynis/docker-alpine.prf" audit system < /dev/null

CMD [ "/bin/bash" ]
