FROM php:7.3-cli-alpine3.10

ENV APP_ENV=${app_env:-"prod"} \
    TIMEZONE=${timezone:-"Asia/Shanghai"} \
    PHPREDIS_VERSION=4.3.0 \
    PHPMONGODB_VERSION=1.5.4 \
    PHPEVENT_VERSION=2.5.3 \
    SWOOLE_VERSION=4.3.5

# Packages
RUN apk --update add \
    autoconf \
    build-base \
    linux-headers \
    libaio-dev \
    libzip \
    libzip-dev \
    zlib-dev \
    curl \
    freetype-dev \
    libjpeg-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libtool \
    libbz2 \
    bzip2 \
    bzip2-dev \
    libstdc++ \
    libxslt-dev \
    libevent-dev \
    openldap-dev \
    imagemagick-dev \
    make \
    unzip \
    wget && \
    docker-php-ext-install bcmath zip bz2 pdo_mysql mysqli simplexml opcache sockets mbstring pcntl xsl && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    pecl install imagick \
    && docker-php-ext-enable imagick \
    && docker-php-ext-enable sockets \
    # Install redis extension
    && wget http://pecl.php.net/get/redis-${PHPREDIS_VERSION}.tgz -O /tmp/redis.tar.tgz \
    && pecl install /tmp/redis.tar.tgz \
    && rm -rf /tmp/redis.tar.tgz \
    && docker-php-ext-enable redis \
    # Install MongoDB extension
    && wget http://pecl.php.net/get/mongodb-${PHPMONGODB_VERSION}.tgz -O /tmp/mongodb.tar.tgz \
    && pecl install /tmp/mongodb.tar.tgz \
    && rm -rf /tmp/mongodb.tar.tgz \
    && docker-php-ext-enable mongodb \
  # Install event extension
    && wget http://pecl.php.net/get/event-${PHPEVENT_VERSION}.tgz -O /tmp/event.tar.tgz \
    && pecl install /tmp/event.tar.tgz \
    && rm -rf /tmp/event.tar.tgz \
    && docker-php-ext-enable --ini-name zz-event.ini event \
    # Install swoole extension
    && wget https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz -O swoole.tar.gz \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && ( \
        cd swoole \
        && phpize \
        && ./configure --enable-mysqlnd --enable-sockets --enable-openssl --enable-http2 \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r swoole \
    && docker-php-ext-enable swoole && \
    docker-php-ext-install gd && \
    docker-php-ext-enable opcache && \
    apk del build-base \
    linux-headers \
    libaio-dev \
    && rm -rf /var/cache/apk/*




ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
ENV COMPOSER_VERSION 1.5.1


RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
 && composer --ansi --version --no-interaction

VOLUME /var/www
WORKDIR /var/www

CMD [ "php", "./public/server.php" ]
