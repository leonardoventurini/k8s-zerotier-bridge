FROM ubuntu:22.04

RUN apt-get update && apt-get install -y supervisor bash curl iptables iproute2
RUN curl -s https://install.zerotier.com | bash

COPY ./files/supervisor-zerotier.conf /etc/supervisor/supervisord.conf
COPY ./files/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

VOLUME ["/var/lib/zerotier-one"]

ENTRYPOINT ["/entrypoint.sh"]
