#!/usr/bin/env bash

# Enable trace printing and exit on the first error
set -ex

use_nfs_for_synced_folders=$1
guest_magento_dir=$2
magento_host_name=$3
use_php7=$4
host_magento_dir=$5
is_windows_host=$6

vagrant_dir="/vagrant"

# Enable Magento virtual host
custom_virtual_host_config="${vagrant_dir}/etc/magento2_virtual_host.conf"
default_virtual_host_config="${vagrant_dir}/etc/magento2_virtual_host.conf.dist"
if [ -f ${custom_virtual_host_config} ]; then
    virtual_host_config=${custom_virtual_host_config}
else
    virtual_host_config=${default_virtual_host_config}
fi
enabled_virtual_host_config="/etc/apache2/sites-available/magento2.conf"
cp ${virtual_host_config}  ${enabled_virtual_host_config}
sed -i "s|<host>|${magento_host_name}|g" ${enabled_virtual_host_config}
sed -i "s|<guest_magento_dir>|${guest_magento_dir}|g" ${enabled_virtual_host_config}
a2ensite magento2.conf

# Disable default virtual host
sudo a2dissite 000-default

# Setup PHP
if [ ${use_php7} -eq 1 ]; then
    sed -i "s|;include_path = \".:/usr/share/php\"|include_path = \".:/usr/share/php:${guest_magento_dir}/vendor/phpunit/phpunit\"|g" /etc/php/7.0/cli/php.ini
    sed -i "s|display_errors = Off|display_errors = On|g" /etc/php/7.0/cli/php.ini
    sed -i "s|display_startup_errors = Off|display_startup_errors = On|g" /etc/php/7.0/cli/php.ini
    sed -i "s|;opcache.enable=0|opcache.enable=1|g" /etc/php/7.0/cli/php.ini
    sed -i "s|;opcache.memory_consumption=64|opcache.memory_consumption=512|g" /etc/php/7.0/cli/php.ini
    sed -i "s|error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT|error_reporting = E_ALL|g" /etc/php/7.0/cli/php.ini
else
    # Uninstall PHP 7 pre-installed in the box
    apt-get remove -y php*

    # Install PHP 5
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
fi
service apache2 restart

# Configure composer
composer_auth_json="${vagrant_dir}/etc/composer/auth.json"
if [ -f ${composer_auth_json} ]; then
    set +x
    echo "Installing composer OAuth tokens from ${composer_auth_json}..."
    set -x
    if [ ! -d /home/vagrant/.composer ] ; then
      sudo -H -u vagrant bash -c 'mkdir /home/vagrant/.composer'
    fi
    if [ -f ${composer_auth_json} ]; then
        cp ${composer_auth_json} /home/vagrant/.composer/auth.json
    fi
fi

# Declare path to scripts supplied with vagrant and Magento
echo "export PATH=\$PATH:${vagrant_dir}/scripts/guest:${guest_magento_dir}/bin" >> /etc/profile
echo "export MAGENTO_ROOT=${guest_magento_dir}" >> /etc/profile
echo "export MAGENTO_ROOT_HOST=${host_magento_dir}" >> /etc/profile
echo "export IS_WINDOWS_HOST=${is_windows_host}" >> /etc/profile

# Set permissions to allow Magento codebase upload by Vagrant provision script
if [ ${use_nfs_for_synced_folders} -eq 0 ]; then
    chown -R vagrant:vagrant /var/www
    chmod -R 755 /var/www
fi
