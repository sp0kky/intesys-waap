# Dockerfile - alpine
# https://github.com/sp0kky/intesys-waap

ARG RESTY_IMAGE_BASE="alpine"
ARG RESTY_IMAGE_TAG="3.15"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

LABEL maintainer="Mirko Spezie <mirko.spezie@gmail.com>"

# Docker Build Arguments
ARG RESTY_IMAGE_BASE="alpine"
ARG RESTY_IMAGE_TAG="3.15"
ARG RESTY_VERSION="1.21.4.1"
ARG RESTY_NGINX="1.21.4"
ARG RESTY_LUAJIT_LIB="/usr/local/openresty/luajit/lib"
#ARG RESTY_LUAJIT_INC="/bin/ls -1 ../ |grep LuaJIT"
ARG RESTY_OPENSSL_VERSION="openssl version"

ARG RESTY_ADD_PACKAGE_BUILDDEPS=""
ARG RESTY_ADD_PACKAGE_RUNDEPS=""
ARG RESTY_EVAL_PRE_CONFIGURE=""
ARG RESTY_EVAL_POST_MAKE=""

# Modsecurity ARGS
ENV MODSEC_AUDIT_LOG_FORMAT="JSON" \
    MODSEC_AUDIT_LOG_TYPE="Serial" \
    MODSEC_AUDIT_LOG="/dev/stdout" \
    MODSEC_AUDIT_STORAGE="/var/log/modsecurity/audit/" \
    MODSEC_DATA_DIR="/tmp/modsecurity/data" \
    MODSEC_DEBUG_LOG="/dev/null" \
    MODSEC_DEBUG_LOGLEVEL="0" \
    MODSEC_PCRE_MATCH_LIMIT_RECURSION="100000" \
    MODSEC_PCRE_MATCH_LIMIT="100000" \
    MODSEC_REQ_BODY_ACCESS="on" \
    MODSEC_REQ_BODY_LIMIT="13107200" \
    MODSEC_REQ_BODY_NOFILES_LIMIT="131072" \
    MODSEC_RESP_BODY_ACCESS="on" \
    MODSEC_RESP_BODY_LIMIT="1048576" \
    MODSEC_RULE_ENGINE="on" \
    MODSEC_TAG="modsecurity" \
    MODSEC_TMP_DIR="/tmp/modsecurity/tmp" \
    MODSEC_UPLOAD_DIR="/tmp/modsecurity/upload" \
    PORT="80" \
    PROXY_TIMEOUT="60s" \
    METRICS_ALLOW_FROM="127.0.0.0/24" \
    METRICS_DENY_FROM="all" \
    WORKER_CONNECTIONS="1024" \
    BACKEND="http://localhost:80" \
    ACCESSLOG="/usr/local/openresty/nginx/logs/access.log" \
    METRICSLOG="/dev/null" \
    ERRORLOG="/usr/local/openresty/nginx/logs/error.log" \
    LOGLEVEL="warn" 

LABEL resty_image_base="${RESTY_IMAGE_BASE}"
LABEL resty_image_tag="${RESTY_IMAGE_TAG}"
LABEL resty_version="${RESTY_VERSION}"
LABEL resty_openssl_version="${RESTY_OPENSSL_VERSION}"
LABEL resty_config_options="${RESTY_CONFIG_OPTIONS}"
LABEL resty_config_options_more="${RESTY_CONFIG_OPTIONS_MORE}"
LABEL resty_config_deps="${_RESTY_CONFIG_DEPS}"
LABEL resty_add_package_builddeps="${RESTY_ADD_PACKAGE_BUILDDEPS}"
LABEL resty_add_package_rundeps="${RESTY_ADD_PACKAGE_RUNDEPS}"
LABEL resty_eval_pre_configure="${RESTY_EVAL_PRE_CONFIGURE}"
LABEL resty_eval_post_make="${RESTY_EVAL_POST_MAKE}"


RUN apk add --no-cache --virtual .build-deps \
        build-base \
        coreutils \
        curl \
        gd-dev \
        geoip-dev \
        libxslt-dev \
        linux-headers \
        make \
        perl-dev \
        readline-dev \
        zlib-dev \
        openssl-dev \
        pcre-dev \
        ccache \
        yajl-dev \
        ${RESTY_ADD_PACKAGE_BUILDDEPS} \
    && apk add --no-cache \
        gd \
        geoip \
        libgcc \
        libstdc++ \
        git \
        libtool \
        automake \
        autoconf \
        libxslt \
        zlib \
        pcre \
        openssl \
        curl \
        yajl \
        ${RESTY_ADD_PACKAGE_RUNDEPS}
RUN git clone https://github.com/SpiderLabs/ModSecurity /tmp/modsecurity \
    && cd /tmp/modsecurity \
    && ./build.sh \
    && git submodule init \
    && git submodule update \
    && ./configure \
    && make \
    && make install
RUN cd /tmp \
    && git clone https://github.com/SpiderLabs/ModSecurity-nginx.git /tmp/modsecurity-nginx \
    && cd /tmp \
    && if [ -n "${RESTY_EVAL_PRE_CONFIGURE}" ]; then eval $(echo ${RESTY_EVAL_PRE_CONFIGURE}); fi
RUN cd /tmp \
    && wget 'http://openresty.org/package/admin@openresty.com-5ea678a6.rsa.pub' \
    && mv 'admin@openresty.com-5ea678a6.rsa.pub' /etc/apk/keys/ \
    && echo "http://openresty.org/package/alpine/v$RESTY_IMAGE_TAG/main" | tee -a /etc/apk/repositories \
    && apk update \
    && apk add openresty=${RESTY_VERSION}-r0
RUN cd /tmp \
    && curl -fkSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd /tmp/openresty-${RESTY_VERSION}/bundle/nginx-${RESTY_NGINX} \
    && export LUAJIT_LIB="${RESTY_LUAJIT_LIB}" \
    && export LUAJIT_INC=../$(ls -1 ../ |grep LuaJIT)/src \
    && echo $LUAJIT_INC > /variables.txt \
    && echo $LUAJIT_LIB >> /variables.txt\
    && export COMPILEOPTIONS=$(openresty -V 2>&1|grep -i "arguments"|cut -d ":" -f2-) \
    && eval ./configure $COMPILEOPTIONS --add-dynamic-module=/tmp/modsecurity-nginx \
    && make -j${RESTY_J} modules
RUN mkdir /usr/local/openresty/nginx/modules \
    && mkdir /usr/local/openresty/nginx/conf/sites-available \
    && mkdir /usr/local/openresty/nginx/conf/sites-enabled \
    && mkdir -p /var/log/modsecurity/audit/ \
    && cp /tmp/openresty-${RESTY_VERSION}/bundle/nginx-${RESTY_NGINX}/objs/ngx_http_modsecurity_module.so /usr/local/openresty/nginx/modules/ \
    && cd /tmp \
    && if [ -n "${RESTY_EVAL_POST_MAKE}" ]; then eval $(echo ${RESTY_EVAL_POST_MAKE}); fi \
    && rm -rf \
        modsecurity modsecurity-nginx \
        openresty-${RESTY_VERSION} openresty-${RESTY_VERSION}.tar.gz \
    && apk del .build-deps \
    && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log \
    && wget --quiet https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping -O /usr/local/openresty/nginx/conf/unicode.mapping \
    && git clone https://github.com/coreruleset/coreruleset.git /usr/local/openresty/nginx/conf/crs
RUN mkdir /usr/local/openresty/nginx/lua_scripts \
    && git clone https://github.com/C0nw0nk/Nginx-Lua-Anti-DDoS.git /usr/local/openresty/nginx/lua_scripts/anti-ddos

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

# Copy nginx configuration files
COPY config.d/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY config.d/logging.conf /usr/local/openresty/nginx/conf/logging.conf
COPY config.d/modsecurity.conf /usr/local/openresty/nginx/conf/modsecurity.conf
COPY config.d/crs-setup.conf /usr/local/openresty/nginx/conf/crs/crs-setup.conf
COPY config.d/nginx.vh.default.conf /usr/local/openresty/nginx/conf/sites-available/default.conf
COPY docker-entrypoint.sh /

RUN apk add moreutils \
        gettext libintl
RUN ln -s /usr/local/openresty/nginx/conf/sites-available/default.conf /usr/local/openresty/nginx/conf/sites-enabled/default.conf
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT
