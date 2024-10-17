FROM php:8.3.8-apache

ARG USERNAME=user
ARG GROUPNAME=user
ARG UID=1000
ARG GID=1000

# ユーザーとグループの作成
RUN groupadd -g $GID $GROUPNAME && \
    useradd -m -u $UID -g $GID $USERNAME && \
    usermod -aG www-data $USERNAME

# 必要なパッケージのインストール
RUN apt-get update && apt-get install --assume-yes --no-install-recommends --quiet \
    unzip \
    vim \
    libicu-dev \
    && docker-php-ext-install \
    pdo_mysql \
    mysqli \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Composerをセットアップ
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Apacheの設定をコピー
COPY ./docker/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf

# headers, rewrite, expiresモジュールを有効化
RUN a2enmod headers rewrite expires
RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

# WP-CLIのインストール
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    php wp-cli.phar --info && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# 作業ディレクトリの設定
WORKDIR /var/www/html

# パーミッションの設定
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html

USER $USERNAME

EXPOSE 80
