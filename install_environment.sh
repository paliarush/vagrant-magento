#!/usr/bin/env bash

# Enable trace printing and exit on the first error
set -ex

apt-get update

# get arguments as an array
args=("$@")

# Determine external IP address
set +x
IP=`ifconfig eth1 | grep inet | awk '{print $2}' | sed 's/addr://'`
echo "IP address is '${IP}'"
set -x

# Determine hostname for Magento web-site
HOST=`hostname -f`
if [ -z ${HOST} ]; then
    # Use external IP address as hostname
    set +x
    HOST=${IP}
    echo "Use IP address '${HOST}' as hostname"
    set -x
fi

# Setup Apache
apt-get install -y apache2
a2enmod rewrite

# Make suer Apache is run from 'vagrant' user to avoid permission issues
sed -i 's/www-data/vagrant/g' /etc/apache2/envvars

# Enable Magento virtual host
magento_dir=${args[0]}
apache_config="/etc/apache2/sites-available/magento2.conf"
cp /vagrant/magento2.vhost.conf  ${apache_config}
sed -i "s/<host>/${HOST}/g" ${apache_config}
sed -i "s|<magento_dir>|${magento_dir}|g" ${apache_config}
a2ensite magento2.conf

# Disable default virtual host
sudo a2dissite 000-default

# Setup PHP
apt-get install -y php5 php5-mhash php5-mcrypt php5-curl php5-cli php5-mysql php5-gd php5-intl php5-xsl php5-xdebug curl
if [ ! -f /etc/php5/apache2/conf.d/20-mcrypt.ini ]; then
    ln -s /etc/php5/mods-available/mcrypt.ini /etc/php5/apache2/conf.d/20-mcrypt.ini
fi
if [ ! -f /etc/php5/cli/conf.d/20-mcrypt.ini ]; then
    ln -s /etc/php5/mods-available/mcrypt.ini /etc/php5/cli/conf.d/20-mcrypt.ini
fi
echo "date.timezone = America/Chicago" >> /etc/php5/cli/php.ini

# Configure XDebug to allow remote connections from the host
echo 'xdebug.max_nesting_level=200
xdebug.remote_enable=1
xdebug.remote_connect_back=1' >> /etc/php5/cli/conf.d/20-xdebug.ini

# Restart Apache
service apache2 restart

# Setup MySQL
debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'
apt-get install -q -y mysql-server-5.6 mysql-client-5.6
mysqladmin -uroot -ppassword password ''

# Make it possible to run 'mysql' without username and password
sed -i '/\[client\]/a \
user = root \
password =' /etc/mysql/my.cnf

# Setup Composer
if [ ! -f /usr/local/bin/composer ]; then
    cd /tmp
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
fi

# Set permissions to allow Magento codebase upload by Vagrant provision script
chown -R vagrant:vagrant /var/www
chmod -R 755 /var/www

# Declare path to scripts supplied with vagrant and Magento
magento_dir="/var/www/magento2ce"
echo "export PATH=\$PATH:/vagrant/bin:${magento_dir}/bin" >> /etc/profile
