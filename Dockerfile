# Much of this stolen from haproxy:1.6 dockerfile, with Lua support
FROM debian:buster

# RUN echo "deb http://mirrors.tencentyun.com/debian buster main" > /etc/apt/sources.list
# RUN echo "deb http://mirrors.tencentyun.com/debian-security buster/updates main" >> /etc/apt/sources.list
# RUN echo "deb http://mirrors.tencentyun.com/debian buster-updates main" >> /etc/apt/sources.list

RUN buildDeps='cron wget python python-setuptools gcc make perl dnsmasq libc6-dev libpcre3-dev zlib1g-dev socat certbot' \
    && set -x \
    && apt-get update && apt-get install --no-install-recommends -yqq $buildDeps

ENV SUPERVISOR_VERSION 4.2.1

RUN wget https://github.com/Supervisor/supervisor/archive/${SUPERVISOR_VERSION}.tar.gz -O supervisor-4.2.1.tar.gz \
    && tar -zxvf supervisor-${SUPERVISOR_VERSION}.tar.gz \
	&& rm supervisor-${SUPERVISOR_VERSION}.tar.gz \
    && cd supervisor-${SUPERVISOR_VERSION} \
	&& python setup.py install \
    && apt-get clean autoclean && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
		
ENV LUA_VERSION 5.4.2

RUN wget http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz \
    && tar -zxvf lua-${LUA_VERSION}.tar.gz \
    && rm lua-${LUA_VERSION}.tar.gz \
    && cd lua-${LUA_VERSION} \
    && make linux \
    && make INSTALL_TOP=/opt/lua install

RUN wget https://github.com/openssl/openssl/archive/OpenSSL_1_1_0l.tar.gz \
	&& tar -zxvf OpenSSL_1_1_0l.tar.gz \
	&& rm OpenSSL_1_1_0l.tar.gz \
	&& cd openssl-OpenSSL_1_1_0l \
	&& ./config shared zlib --prefix=/usr/local/openssl-1.1.0 --openssldir=/usr/local/openssl-1.1.0/ssl \
	&& make && make install \
	&& cp /usr/local/openssl-1.1.0/lib/libssl.so.1.1 /lib/x86_64-linux-gnu \
	&& cp /usr/local/openssl-1.1.0/lib/libcrypto.so.1.1 /lib/x86_64-linux-gnu
	
ENV HAPROXY_MAJOR 2.3
ENV HAPROXY_VERSION 2.3.2
ENV HAPROXY_MD5 3b1143f2e38dbbb41cfa0996666c971c

RUN wget http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz \
	&& echo "${HAPROXY_MD5} haproxy-${HAPROXY_VERSION}.tar.gz" | md5sum -c \
	&& mkdir -p /usr/src/haproxy \
	&& tar -zxvf haproxy-${HAPROXY_VERSION}.tar.gz -C /usr/src/haproxy --strip-components=1 \
	&& rm haproxy-${HAPROXY_VERSION}.tar.gz \
	&& make -C /usr/src/haproxy \
		TARGET=linux-glibc \
		ARCH=x86_64 \
		USE_PCRE=1 PCREDIR= \
		USE_OPENSSL=1 \
		SSL_LIB=/usr/local/openssl-1.1.0/lib \
		SSL_INC=/usr/local/openssl-1.1.0/include \
		USE_ZLIB=1 \
		USE_LUA=yes LUA_LIB=/opt/lua/lib/ \
        	LUA_INC=/opt/lua/include/ LDFLAGS=-ldl \
		all \
		install-bin \
	&& mkdir -p /usr/local/etc/haproxy \
	&& cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors \
	&& rm -rf /usr/src/haproxy

COPY docker-entrypoint.sh /

# See https://github.com/janeczku/haproxy-acme-validation-plugin
COPY haproxy-acme-validation-plugin/acme-http01-webroot.lua /usr/local/etc/haproxy
COPY haproxy-acme-validation-plugin/cert-renewal-haproxy.sh /

COPY crontab.txt /var/crontab.txt
RUN crontab /var/crontab.txt && chmod 600 /etc/crontab

COPY supervisord.conf /etc/supervisord.conf
COPY certs.sh /
COPY bootstrap.sh /
COPY haproxy-systemd-wrapper /usr/local/sbin

RUN chmod 755 /usr/local/sbin/haproxy-systemd-wrapper

RUN mkdir /jail

EXPOSE 80 443

VOLUME /etc/letsencrypt

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

ENTRYPOINT ["/bootstrap.sh"]
