FROM httpd:2.4

# Install openssl
RUN apt-get update && \
    apt-get install -y openssl && \
    rm -rf /var/lib/apt/lists/*

# Enable required modules
RUN sed -i \
    -e 's/^#\(LoadModule ssl_module .*\)/\1/' \
    -e 's/^#\(LoadModule socache_shmcb_module .*\)/\1/' \
    -e 's/^#\(LoadModule proxy_module .*\)/\1/' \
    -e 's/^#\(LoadModule proxy_http_module .*\)/\1/' \
    -e 's/^#\(LoadModule proxy_connect_module .*\)/\1/' \
    -e 's/^#\(LoadModule proxy_fcgi_module .*\)/\1/' \
    -e 's/^#\(LoadModule headers_module .*\)/\1/' \
    -e 's/^#\(LoadModule rewrite_module .*\)/\1/' \
    /usr/local/apache2/conf/httpd.conf

# Add Listen 443 manually (jangan uncomment httpd-ssl.conf)
RUN echo 'Listen 443' >> /usr/local/apache2/conf/httpd.conf

# Global config - applies to all VirtualHosts
# Penjelasan Global config: ./ssl_session_cache.md
RUN echo 'ServerName leap_apache2-httpd' >> /usr/local/apache2/conf/httpd.conf && \
    echo 'SSLSessionCache shmcb:/usr/local/apache2/logs/ssl_scache(512000)' >> /usr/local/apache2/conf/httpd.conf

# Copy custom VirtualHost config
COPY 000-default.conf /usr/local/apache2/conf/extra/website_ssl.conf

# Include custom config
RUN echo 'Include conf/extra/website_ssl.conf' >> /usr/local/apache2/conf/httpd.conf

# Copy web files
COPY ./web_files /usr/local/apache2/htdocs

# Setup entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["httpd-foreground"]