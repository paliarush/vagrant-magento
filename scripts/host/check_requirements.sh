#!/usr/bin/env bash

vagrant_dir=$(cd "$(dirname "$0")/../.."; pwd)
composer_auth_json="${vagrant_dir}/etc/composer/auth.json"
php_executable=$(bash "${vagrant_dir}/scripts/host/get_path_to_php.sh")

# Enable trace printing and exit on the first error
set -ex

if ! ${php_executable} -v | grep -q 'Copyright' ; then
    bash "${vagrant_dir}/scripts/host/install_php.sh"
fi
