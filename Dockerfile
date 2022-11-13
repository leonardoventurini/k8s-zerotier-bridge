FROM alpine
MAINTAINER Leonardo Venturini - leovenbag@gmail.com

ENV ZEROTIER_VERSION=1.10.2

RUN apk add zerotier-one=${ZEROTIER_VERSION}-r0

COPY files/supervisor-zerotier.conf /etc/supervisor/supervisord.conf
COPY files/entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

VOLUME ["/var/lib/zerotier-one"]
ENTRYPOINT ["/entrypoint.sh"]
