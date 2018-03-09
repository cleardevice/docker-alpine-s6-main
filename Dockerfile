FROM cleardevice/docker-alpine-s6-main:alpine-3.7

MAINTAINER cd <cleardevice@gmail.com>

# Nginx version
ENV NGINX_VERSION=1.13.9 NGINX_HOME=/usr/share/nginx REDIS_NGINX_MODULE=0.3.9 NGINX_DEVEL_KIT_MODULE=0.3.1rc1 \
    LUA_NGINX_MODULE=0.10.12rc2 LUA_ROCKS=2.4.3

RUN apk add --no-cache openssl-dev zlib-dev pcre-dev build-base autoconf automake libtool && \
    cd /tmp && git clone https://github.com/google/ngx_brotli.git && \
    cd /tmp/ngx_brotli && git submodule update --init && \
    cd /tmp && git clone https://github.com/bagder/libbrotli.git && \
    cd /tmp/libbrotli && ./autogen.sh && ./configure && make && \
    # nginx_devel_kit
    curl -Ls https://github.com/simplresty/ngx_devel_kit/archive/v${NGINX_DEVEL_KIT_MODULE}.tar.gz | tar -xz -C /tmp && \
    # luajit-2.0
    cd /tmp && git clone http://luajit.org/git/luajit-2.0.git && \
    cd /tmp/luajit-2.0 && make && make install && \
    # luarocks
    curl -Ls http://luarocks.github.io/luarocks/releases/luarocks-${LUA_ROCKS}.tar.gz | tar -xz -C /tmp && \
    cd /tmp/luarocks-${LUA_ROCKS} && ./configure --lua-suffix=jit --with-lua=/usr/local --with-lua-include=/usr/local/include/luajit-2.0 && \
    make build && make install && \
    # lua_nginx_module
    mkdir /tmp/lua_nginx_moudle && \
    curl -Ls https://github.com/openresty/lua-nginx-module/archive/v${LUA_NGINX_MODULE}.tar.gz | tar -xz -C /tmp/lua_nginx_moudle --strip-components=1 && \
    # redis-nginx-module
    curl -Ls https://github.com/onnimonni/redis-nginx-module/archive/v${REDIS_NGINX_MODULE}.tar.gz | tar -xz -C /tmp && \
    # ngx_aws_auth module
    cd /tmp && git clone -b AuthV2 https://github.com/anomalizer/ngx_aws_auth.git && \
    # nginx
    curl -Ls http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar -xz -C /tmp && \
    cd /tmp/nginx-${NGINX_VERSION} && \
    # configure
    ./configure \
        --with-debug \
        --with-ipv6 \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-stream \
        --with-stream_ssl_preread_module \
        --add-module=/tmp/redis-nginx-module-${REDIS_NGINX_MODULE} \
        --add-module=/tmp/ngx_brotli \
        --add-module=/tmp/ngx_aws_auth \
        --add-module=/tmp/ngx_devel_kit-${NGINX_DEVEL_KIT_MODULE} \
        --add-module=/tmp/lua_nginx_moudle \
        --prefix=${NGINX_HOME} \
        --conf-path=/etc/nginx/nginx.conf \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx.pid \
        --sbin-path=/usr/sbin/nginx && \
    make && \
    make install && mkdir -p /etc/nginx/conf.d && \
    apk del build-base autoconf automake libtool && \
    rm -rf /tmp/* && rm -rf /var/cache/apk/*

RUN luarocks install uuid

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443
