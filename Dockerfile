FROM php:7.2-alpine

# Repo update and installations
RUN apk update 
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN apk add --no-cache apache2 php7-apache2 php7-mysqli php7-soap php7-gd php7-zip php7-pdo php7-mbstring php7-json php7-curl php7-ctype php7-zlib php7-session php7-dom php7-openssl php7-xml php7-simplexml php7-fileinfo php7-tokenizer php7-iconv php7-opcache php7-xdebug php7-phar php7-intl php7-apcu php7-xmlwriter php7-pdo_sqlite openssl imagemagick curl
RUN docker-php-ext-install mysqli

# Replace default webroot
RUN awk 'NR==245, NR==246{sub("/var/www/localhost/htdocs","/var/www/html/public")};1' /etc/apache2/httpd.conf > /etc/apache2/httpd_tmp.conf && mv /etc/apache2/httpd_tmp.conf /etc/apache2/httpd.conf

# Edit php.ini
RUN awk 'NR==388{sub("max_execution_time = 30","max_execution_time = 240")};1' /etc/php7/php.ini > /etc/php7/php_tmp.ini && mv /etc/php7/php_tmp.ini /etc/php7/php.ini 
RUN awk 'NR==405{sub(";max_input_vars = 1000","max_input_vars = 1500")};1' /etc/php7/php.ini > /etc/php7/php_tmp.ini && mv /etc/php7/php_tmp.ini /etc/php7/php.ini
RUN awk 'NR==926, NR==936{sub(";","")};1' /etc/php7/php.ini > /etc/php7/php_tmp.ini && mv /etc/php7/php_tmp.ini /etc/php7/php.ini
# RUN chmod -R +rw  apache:apache /var/log/apache2

# Install composer manually (version from apk depends on php8)
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Install typo3
RUN cd /var/www/html/ && composer create-project "typo3/cms-base-distribution:^10.4" . && composer require helhum/typo3-console 

# Create FIRST_INSTALL
# Run touch /var/www/html/public/FIRST_INSTALL

# Automatic setup
RUN /var/www/html/vendor/bin/typo3cms install:setup --no-interaction \
   --database-driver="pdo_sqlite" \
   --database-name="typo3sqlite.db" \
   --admin-user-name="admin" \
   --admin-password="password" \
   --site-name="Fast typo3" \
   --site-setup-type="site"


# Transfer ownership to apache
RUN chown -R apache:apache /var/www/html && chown -R apache:apache /var/log/apache2 && chown -R apache:apache /run/apache2


USER apache:apache

# start httpd
CMD ["httpd", "-D", "FOREGROUND"]

