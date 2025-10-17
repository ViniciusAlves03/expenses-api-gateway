FROM kong:3.7.1
USER root

RUN apt-get update && \
apt-get install -y wget netcat python3 python3-pip && \
PYTHONWARNINGS=ignore pip3 install kong-pdk==0.33 PyJWT==2.9.0 requests==2.32.3

RUN wget https://github.com/kong/deck/releases/download/v1.40.3/deck_1.40.3_linux_amd64.tar.gz; \
  tar -xf deck_1.40.3_linux_amd64.tar.gz -C /tmp; cp /tmp/deck /usr/local/bin/; rm -rf deck.tar.gz /tmp/deck

COPY ./config /etc/kong

RUN mv /etc/kong/plugins/jwt/handler.lua /usr/local/share/lua/5.1/kong/plugins/jwt/handler.lua; \
  mv /etc/kong/plugins/acl/handler.lua /usr/local/share/lua/5.1/kong/plugins/acl/handler.lua

WORKDIR /opt/kong-python-pdk

USER kong
ENTRYPOINT ["/etc/kong/start.sh"]
EXPOSE 8000 8443 8001 8444
STOPSIGNAL SIGQUIT
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
