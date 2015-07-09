FROM alpine:latest
MAINTAINER Bob Aman <bob@sporkmonger.com>

RUN apk add --update bash && rm -rf /var/cache/apk/*

# I just can't deal with terminals that don't have pretty colors.
ENV PS1="\\[\\033[01;32m\\]\\u@\\h\\[\\033[01;34m\\] \\w \\$\\[\\033[00m\\] " \
  TERM="xterm-color"

RUN mkdir -p /opt/bin /opt/var/cveck
COPY ./tests /opt/var/cveck
COPY ./cveck /opt/bin/cveck
RUN chmod a+x /opt/var/cveck/*_test.sh && chmod a+x /opt/bin/cveck
RUN /opt/bin/cveck

CMD [ "/bin/bash" ]
