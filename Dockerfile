FROM alpine:latest

RUN apk add --update zerotier-one supervisor bash iptables openrc curl

COPY ./files/supervisor-zerotier.conf /etc/supervisor/supervisord.conf
COPY ./files/entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

VOLUME ["/var/lib/zerotier-one"]

ENTRYPOINT ["/entrypoint.sh"]
