#!/bin/bash

  echo "### setting hostname"
  hostname scruno-board.local
  if [ -z `grep -Fl scruno-board.local /etc/hosts` ]; then
    echo >>/etc/hosts
    echo "192.158.50.51 scruno-board.local" >>/etc/hosts
  fi

  echo "### Fixing dns entries"
  sed -i -e"s/domain-name-servers, //g" /etc/dhcp/dhclient.conf
  if [ -z `grep -Fl 8.8.8.8 /etc/dhcp/dhclient.conf` ]; then
    echo >>/etc/dhcp/dhclient.conf
    echo "prepend domain-name-servers 8.8.8.8,8.8.4.4;" >>/etc/dhcp/dhclient.conf
  fi
  (dhclient -r && dhclient eth0)

  echo "### install base system"
  yum install -y php httpd mysql-server libmemcached php-xml php-bcmath php-cli php-mbstring php-mysql php-process php-pecl-memcache php-curl php-intl php-pear git

  echo "### install php dev utils"
  pear upgrade pear
  pear channel-discover pear.phpunit.de
  pear channel-discover components.ez.no
  pear channel-discover pear.symfony.com
  pear channel-discover pear.phing.info

  pear install --alldeps phpunit/PHPUnit
  pear install phing/phing

  echo "### setting up php"
  PHP_SETTINGS='
    display_errors=on
    open_basedir=none
    upload_max_filesize=50M
    post_max_size=50M
    max_execution_time=0
    date.timezone="Europe/London"
  '
  echo "${PHP_SETTINGS}" >/etc/php.d/90-vagrant-settings.ini

  # echo "### Configure MySql for remote connections"
  # sed -i -e"s/127.0.0.1/0.0.0.0/g" /etc/my.cnf
  # mysql -uroot -e"GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"

  echo "### Configuring Apache"
  APACHE_CONFIG='
  <VirtualHost *:80>
    DocumentRoot "/var/www/html/web"
    ServerName scrunno.local
    #ErrorLog "/srv/www/v2/data/logs/error_log"
    #CustomLog "/srv/www/v2/data/logs/access_log" common
    <Directory /var/www/html/web>
      AllowOverride All
      Options Indexes FollowSymLinks
      Order allow,deny
      Allow from all
    </Directory>
  </VirtualHost>
  '
  echo "${APACHE_CONFIG}" >/etc/httpd/conf.d/scrunno.conf
  a2enmod rewrite

  echo "### stop selinux"
  setenforce 0

  echo "### starting services"
  service httpd restart
  service mysqld restart

exit 0
