FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    nginx \
    curl \
    vim \
    net-tools \
    iputils-ping \
    iptables \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/empresa/public_html

COPY site/index.html /var/www/empresa/public_html/index.html
COPY configs/empresa.conf /etc/nginx/sites-available/empresa
COPY entrypoint.sh /entrypoint.sh

RUN ln -s /etc/nginx/sites-available/empresa \
          /etc/nginx/sites-enabled/empresa \
    && rm -f /etc/nginx/sites-enabled/default

RUN chown -R www-data:www-data /var/www/empresa/ \
    && chmod -R 755 /var/www/empresa/

RUN touch /var/log/nginx/empresa_access.log \
          /var/log/nginx/empresa_error.log \
    && chown www-data:adm /var/log/nginx/empresa_access.log \
                          /var/log/nginx/empresa_error.log \
    && chmod 640 /var/log/nginx/empresa_access.log \
                 /var/log/nginx/empresa_error.log

EXPOSE 80

CMD ["/entrypoint.sh"]
