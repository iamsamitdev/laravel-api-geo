FROM php:8.3-cli-alpine

RUN apk add --no-cache icu-libs sqlite-libs libzip \
 && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS icu-dev libzip-dev \
 && docker-php-ext-install -j"$(nproc)" pdo_sqlite pdo_mysql bcmath intl zip opcache \
 && apk del .build-deps

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# ติดตั้ง dependency ก่อนคัดลอกโค้ด เพื่อให้ layer cache ทำงาน
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction

COPY . .
RUN composer dump-autoload --optimize --no-dev \
 && chmod +x docker-entrypoint.sh

# opcache สำหรับ production
RUN { \
      echo 'opcache.enable=1'; \
      echo 'opcache.enable_cli=0'; \
      echo 'opcache.memory_consumption=96'; \
      echo 'opcache.validate_timestamps=0'; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# php artisan serve รับทีละ request ถ้าไม่ตั้งค่านี้ (Astro build ยิงพร้อมกันหลาย endpoint)
ENV PHP_CLI_SERVER_WORKERS=4

EXPOSE 10000

ENTRYPOINT ["./docker-entrypoint.sh"]
