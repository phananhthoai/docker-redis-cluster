FROM ubuntu:22.04

RUN yes | unminized

COPY common.sh /
RUN /common.sh

COPY scripts/ /scripts/

ENTRYPOINT [ "/lib/systemd/systemd" ]