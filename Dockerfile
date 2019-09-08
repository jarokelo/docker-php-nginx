FROM jarokelo/debian:stretch

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https lsb-release ca-certificates \
    wget \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && apt-get purge -y --auto-remove wget \
    && \
    rm -rf /var/lib/apt/lists/* \
    && \
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && echo "deb-src https://packages.sury.org/php/ $(lsb_release -sc) main" >> /etc/apt/sources.list.d/php.list

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    nginx \
    php7.1-cli \
    php7.1-gd php7.1-curl php7.1-intl php7.1-mysql php7.1-pgsql \
    php7.1-sqlite3 php7.1-xmlrpc php7.1-xsl php7.1-json \
    php7.1-memcache php7.1-mcrypt php7.1-imap \
    php7.1-mbstring \
    php7.1-zip \
    php7.1-soap \
    rsyslog \
    python \
    python-setuptools \
    python-pkg-resources \
    ssmtp \
    && easy_install supervisor \
    && apt-get purge -y --auto-remove python-setuptools \
    && \
    rm -rf /var/lib/apt/lists/*

ADD php.ini /etc/php/7.1/apache2/php.ini
ADD php.ini /etc/php/7.1/cli/php.ini

# download and install go-cron
ENV GO_CRON 0.2.1
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    && \
    curl -SL "https://github.com/nkovacs/go-cron/releases/download/$GO_CRON/go-cron-linux-amd64" -o /usr/local/bin/go-cron \
    && chmod a+x /usr/local/bin/go-cron \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

RUN rm -rf /var/www/html && mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

ENV CRON_WORKDIR="/var/www/html"

ADD supervisor-watcher /usr/local/bin/supervisor-watcher
ADD sigproxy /usr/local/bin/sigproxy

# add supervisor config
ADD supervisord.conf /etc/supervisor/supervisord.conf
ADD supervisor/* /etc/supervisor/conf.d/
# create log directory
RUN mkdir -p /var/log/supervisor

# add syslog config
ADD rsyslog.conf /etc/rsyslog.conf

ADD ssmtp.conf /etc/ssmtp/ssmtp.conf

WORKDIR /var/www/html

EXPOSE 80
CMD ["/usr/local/bin/supervisord"]
