#!/usr/bin/env bash

# Enable trace printing and exit on the first error
set -ex

is_windows_host=$1
guest_magento_dir=$2
magento_host_name=$3

vagrant_dir="/vagrant"

# connect epel repo
yum install -y epel-release
# connect remi repo and enable it
rpm -i http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
yum-config-manager --enable remi remi-php70
# connect mysql repo
rpm -i https://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm

# update vm
yum update -y

# Install git and apache
yum install -y git httpd

# Make suer Apache is run from 'vagrant' user to avoid permission issues
sed -i 's|User\ apache|User\ vagrant|g' /etc/httpd/conf/httpd.conf

# Enable Magento virtual host
custom_virtual_host_config="${vagrant_dir}/local.config/magento2_virtual_host.conf"
default_virtual_host_config="${vagrant_dir}/local.config/magento2_virtual_host.conf.dist"
if [ -f ${custom_virtual_host_config} ]; then
    virtual_host_config=${custom_virtual_host_config}
else
    virtual_host_config=${default_virtual_host_config}
fi
enabled_virtual_host_config="/etc/httpd/conf.d/magento2.conf"
cp ${virtual_host_config}  ${enabled_virtual_host_config}
sed -i "s|<host>|${magento_host_name}|g" ${enabled_virtual_host_config}
sed -i "s|<guest_magento_dir>|${guest_magento_dir}|g" ${enabled_virtual_host_config}

# Setup PHP
    yum install -y php php-bcmath php-cli php-common php-gd php-intl php-json php-mbstring php-mcrypt php-mysqlnd php-opcache php-pdo php-pear php-pecl-xdebug php-precess php-soap php-xml

    ## Configure XDebug to allow remote connections from the host
    echo 'zend_extension=xdebug.so
    xdebug.max_nesting_level=200
    xdebug.remote_enable=1
    xdebug.remote_connect_back=1' >> /etc/php.d/15-xdebug.ini

    echo "date.timezone = America/Chicago" >> /etc/php.ini
    sed -i "s|;include_path = \".:/usr/share/php\"|include_path = \".:/usr/share/php:${guest_magento_dir}/vendor/phpunit/phpunit\"|g" /etc/php.ini

# Restart Apache
systemctl restart httpd

# Setup MySQL
yum install -y mysql-community-server mysql-community-client
systemctl restart mysqld

# Setup Composer
if [ ! -f /usr/local/bin/composer ]; then
    cd /tmp
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
fi

# Configure composer
composer_auth_json="${vagrant_dir}/local.config/composer/auth.json"
if [ -f ${composer_auth_json} ]; then
    set +x
    echo "Installing composer OAuth tokens from ${composer_auth_json}..."
    set -x
    if [ ! -d /home/vagrant/.composer ] ; then
      sudo -H -u vagrant bash -c 'mkdir /home/vagrant/.composer'
    fi
    cp ${composer_auth_json} /home/vagrant/.composer/auth.json
fi

# Declare path to scripts supplied with vagrant and Magento
echo "export PATH=\$PATH:${vagrant_dir}/scripts/guest:${guest_magento_dir}/bin" >> /etc/profile
echo "export MAGENTO_ROOT=${guest_magento_dir}" >> /etc/profile

# Set permissions to allow Magento codebase upload by Vagrant provision script
if [ ${is_windows_host} -eq 1 ]; then
    chown -R vagrant:vagrant /var/www
    chmod -R 755 /var/www
fi

# Install RabbitMQ (is used by Enterprise edition)
yum install -y rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
systemctl restart rabbitmq-server
