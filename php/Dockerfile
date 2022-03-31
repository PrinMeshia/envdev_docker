FROM php:8.0.16-apache
ARG USER=docker
ARG UID=1000
ARG GID=1000
RUN mkdir -p /etc/apache2
RUN mkdir -p /etc/apache2/mods-available

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN apt-get update \
    && apt-get install -y --no-install-recommends \ 
    locales \
    apt-utils \
    git \
    curl \
    libzip-dev \
    unzip \
    libicu-dev g++ \
    libpng-dev \
    libxml2-dev \
    libonig-dev \
    libxslt-dev \
    zlib1g-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libsodium-dev;

RUN curl -sL https://deb.nodesource.com/setup_17.x | bash -
RUN apt-get update \
 && apt-get install -y \
 nodejs
RUN npm install -g yarn  

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

RUN curl -sSk https://getcomposer.org/installer | php -- --disable-tls && \
   mv composer.phar /usr/local/bin/composer

RUN useradd -G www-data,root -u $UID $USER -d /home/$USER 
RUN mkdir -p /home/$USER/.composer && \
    chown -R $USER:$user /home/$USER

RUN cp /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/ && \
    cp /etc/apache2/mods-available/headers.load /etc/apache2/mods-enabled/ && \
    cp /etc/apache2/mods-available/expires.load /etc/apache2/mods-enabled/

RUN docker-php-ext-configure intl
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) gd
RUN docker-php-ext-install pdo pdo_mysql opcache intl zip calendar dom mbstring gd xsl exif sodium 
RUN pecl install apcu && docker-php-ext-enable apcu

RUN echo 'alias symfony="php bin/console"' >> ~/.bashrc
RUN echo 'alias artisan="php artisan"' >> ~/.bashrc


WORKDIR /var/www/
USER $user
