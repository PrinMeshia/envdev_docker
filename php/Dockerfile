
FROM php:7.4.1-apache
USER root
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN apt-get update \
    && apt-get install -y --no-install-recommends \ 
    locales \
    apt-utils \
    git \
    libicu-dev g++ \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    libonig-dev \
    libxslt-dev \
    zlib1g-dev \
    libjpeg-dev \
    libfreetype6-dev;

RUN curl -sL https://deb.nodesource.com/setup_15.x | bash -
RUN apt-get update \
 && apt-get install -y \
 nodejs
RUN npm install -g yarn  

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

RUN curl -sSk https://getcomposer.org/installer | php -- --disable-tls && \
   mv composer.phar /usr/local/bin/composer

RUN cp /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/ && \
    cp /etc/apache2/mods-available/headers.load /etc/apache2/mods-enabled/ && \
    cp /etc/apache2/mods-available/expires.load /etc/apache2/mods-enabled/

RUN docker-php-ext-configure intl
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) gd
RUN docker-php-ext-install pdo pdo_mysql opcache intl zip calendar dom mbstring zip gd xsl
RUN pecl install apcu && docker-php-ext-enable apcu

RUN echo 'alias symfony="php bin/console"' >> ~/.bashrc

WORKDIR /var/www/



