#!/usr/bin/env bash

vagrant_dir=$PWD
magento_ce_dir="${vagrant_dir}/magento2ce"
magento_ee_dir="${magento_ce_dir}/magento2ee"
config_path="${vagrant_dir}/etc/config.yaml"
host_os=$(bash "${vagrant_dir}/scripts/host/get_host_os.sh")

# Enable trace printing and exit on the first error
set -ex

bash "${vagrant_dir}/scripts/host/check_requirements.sh"

# Install necessary vagrant plugins if not installed
vagrant_plugin_list=$(vagrant plugin list)
if ! echo ${vagrant_plugin_list} | grep -q 'vagrant-hostmanager' ; then
    vagrant plugin install vagrant-hostmanager
fi
if ! echo ${vagrant_plugin_list} | grep -q 'vagrant-vbguest' ; then
    vagrant plugin install vagrant-vbguest
fi
if ! echo ${vagrant_plugin_list} | grep -q 'vagrant-host-shell' ; then
    vagrant plugin install vagrant-host-shell
fi

# Generate random IP address and host name to prevent collisions, if not specified explicitly in local config
if [[ ! -f "${vagrant_dir}/etc/config.yaml" ]]; then
    cp "${config_path}.dist" ${config_path}
fi
random_ip=$(( ( RANDOM % 240 )  + 12 ))
forwarded_ssh_port=$(( random_ip + 3000 ))
sed -i.back "s|ip_address: \"192.168.10.2\"|ip_address: \"192.168.10.${random_ip}\"|g" "${config_path}"
sed -i.back "s|host_name: \"magento2.vagrant2\"|host_name: \"magento2.vagrant${random_ip}\"|g" "${config_path}"
sed -i.back "s|forwarded_ssh_port: 3000|forwarded_ssh_port: ${forwarded_ssh_port}|g" "${config_path}"
rm -f "${config_path}.back"

# Clean up the project before initialization if "-f" option was specified. Remove codebase if "-fc" is used.
force_project_cleaning=0
force_codebase_cleaning=0
force_phpstorm_config_cleaning=0
while getopts 'fcp' flag; do
  case "${flag}" in
    f) force_project_cleaning=1 ;;
    c) force_codebase_cleaning=1 ;;
    p) force_phpstorm_config_cleaning=1 ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done
if [[ ${force_project_cleaning} -eq 1 ]]; then
    vagrant destroy -f
    mv ${vagrant_dir}/etc/guest/.gitignore ${vagrant_dir}/etc/.gitignore.back
    rm -rf ${vagrant_dir}/.vagrant ${vagrant_dir}/etc/guest
    mkdir ${vagrant_dir}/etc/guest
    mv ${vagrant_dir}/etc/.gitignore.back  ${vagrant_dir}/etc/guest/.gitignore
    if [ ${force_codebase_cleaning} -eq 1 ]; then
        rm -rf ${magento_ce_dir}
    fi
fi

if [[ ! -d ${magento_ce_dir} ]]; then
    if [[ ${host_os} == "Windows" ]]; then
        git config --global core.autocrlf false
        git config --global core.eol LF
        git config --global diff.renamelimit 5000
    fi
    # Check out CE repository
    repository_url_ce=$(bash "${vagrant_dir}/scripts/get_config_value.sh" "repository_url_ce")
    git clone ${repository_url_ce} ${magento_ce_dir}
    # Check out EE repository
    # By default EE repository is not specified and EE project is not checked out
    repository_url_ee=$(bash "${vagrant_dir}/scripts/get_config_value.sh" "repository_url_ee")
    if [ -n "${repository_url_ee}" ]; then
        git clone ${repository_url_ee} ${magento_ee_dir}
    fi
fi

# Update Magento dependencies via Composer
cd ${magento_ce_dir}
bash "${vagrant_dir}/scripts/host/composer.sh" install

# Create vagrant project
cd ${vagrant_dir}
vagrant up

set +x
echo "Configuring PhpStorm..."
if [[ ${force_project_cleaning} -eq 1 ]] && [[ ${force_phpstorm_config_cleaning} -eq 1 ]]; then
    rm -rf ${vagrant_dir}/.idea
fi
if [[ ! "$(ls -A ${vagrant_dir}/.idea)" ]]; then
    bash "${vagrant_dir}/scripts/host/configure_php_storm.sh"
fi

bold=$(tput bold)
regular=$(tput sgr0)
echo "
${bold}[Important]${regular}
    Please use ${bold}${vagrant_dir}${regular} directory as PhpStorm project root, NOT ${bold}${magento_ce_dir}${regular}."

use_nfs=$(bash "${vagrant_dir}/scripts/get_config_value.sh" "guest_use_nfs")
if [[ ${host_os} == "Windows" || ${use_nfs} == 0 ]]; then
    echo "
${bold}[Optional]${regular}
    To verify that deployment configuration for ${bold}${magento_ce_dir}${regular} in PhpStorm is correct,
        use instructions provided here: ${bold}https://github.com/paliarush/magento2-vagrant-for-developers/blob/2.0/docs/phpstorm-configuration-windows-hosts.md${regular}.
    If not using PhpStorm, you can set up synchronization using rsync"
fi
