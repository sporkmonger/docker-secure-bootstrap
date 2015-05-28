FROM alpine:latest
MAINTAINER Bob Aman <bob@sporkmonger.com>

RUN apk add --update bash && rm -rf /var/cache/apk/*

# I just can't deal with terminals that don't have pretty colors.
ENV PS1="\[\033[01;32m\]\u@\h\[\033[01;34m\] \w \$\[\033[00m\] " \
  TERM="xterm-color"

#RUN mkdir -p ~/tests
COPY ./tests /root/tests
COPY ./run.sh /root/run.sh
RUN ls -al /root
RUN ls -al /root/tests
RUN chmod a+x /root/tests/*.sh && chmod a+x /root/run.sh
RUN /root/run.sh && rm -rf /root/tests/ && rm -rf /root/run.sh

CMD [ "/bin/bash" ]
