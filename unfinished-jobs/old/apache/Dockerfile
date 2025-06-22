FROM ubuntu:24.10

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apache2 \
    php \
    php-mysql \
    libapache2-mod-php \
    openssl \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod ssl proxy proxy_http rewrite && \
    a2ensite default-ssl

COPY 000-default.conf /etc/apache2/sites-available/
COPY docker-entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

VOLUME ["/etc/ssl/certs", "/etc/ssl/private"]
EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2ctl", "-D", "FOREGROUND"]