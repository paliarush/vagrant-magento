#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")/../.." && vagrant_dir=$PWD

source "${vagrant_dir}/scripts/output_functions.sh"

status "Creating configuration for Magento Tests"
incrementNestingLevel

magento_host_name="$(bash "${vagrant_dir}/scripts/get_config_value.sh" "magento_host_name")"
magento_admin_frontname="$(bash "${vagrant_dir}/scripts/get_config_value.sh" "magento_admin_frontname")"
magento_admin_user="$(bash "${vagrant_dir}/scripts/get_config_value.sh" "magento_admin_user")"
magento_admin_password="$(bash "${vagrant_dir}/scripts/get_config_value.sh" "magento_admin_password")"

function setup_test_configuration_files() {
    magento_root=$1
    magento_tests_root="${magento_root}/dev/tests"

    status "Setting up test configuration files for Magento installation in \"${magento_root}\"."
    incrementNestingLevel

    # Unit tests
    if [[ ! -f "${magento_tests_root}/unit/phpunit.xml" ]] && [[ -f "${magento_tests_root}/unit/phpunit.xml.dist" ]]; then
        status "Creating configuration for Unit tests"
        cp "${magento_tests_root}/unit/phpunit.xml.dist" "${magento_tests_root}/unit/phpunit.xml"
    fi

    # Integration tests
    if [[ ! -f "${magento_tests_root}/integration/phpunit.xml" ]] && [[ -f "${magento_tests_root}/integration/phpunit.xml.dist" ]]; then
        status "Creating configuration for Integration tests"
        cp "${magento_tests_root}/integration/phpunit.xml.dist" "${magento_tests_root}/integration/phpunit.xml"
        sed -i.back "s|<const name=\"TESTS_CLEANUP\" value=\"enabled\"/>|<const name=\"TESTS_CLEANUP\" value=\"disabled\"/>|g" "${magento_tests_root}/integration/phpunit.xml"
        rm -f "${magento_tests_root}/integration/phpunit.xml.back"

        if [[ ! -f "${magento_tests_root}/integration/etc/install-config-mysql.php" ]] && [[ -f "${magento_tests_root}/integration/etc/install-config-mysql.php.dist" ]]; then
            cp "${magento_tests_root}/integration/etc/install-config-mysql.php.dist" "${magento_tests_root}/integration/etc/install-config-mysql.php"
            sed -i.back "s|'db-password' => '123123q'|'db-password' => ''|g" "${magento_tests_root}/integration/etc/install-config-mysql.php"
            # Add configuration for RabbitMQ if it exists.
            if [[ -d "${magento_root}/app/code/Magento/MessageQueue" ]] || [[ -d "${magento_root}/vendor/magento/magento-message-queue" ]]; then
                sed -i.back "s|\];|\\
                'amqp-host' => 'localhost',\\
                'amqp-port' => '5672',\\
                'amqp-user' => 'guest',\\
                'amqp-password' => 'guest'\\
                ];|g" "${magento_tests_root}/integration/etc/install-config-mysql.php"
            fi
            rm -f "${magento_tests_root}/integration/etc/install-config-mysql.php.back"
        fi
    fi

    # Web API tests (api-functional)
    if [[ ! -f "${magento_tests_root}/api-functional/rest.xml" ]] && [[ -f "${magento_tests_root}/api-functional/phpunit.xml.dist" ]]; then
        status "Creating configuration for REST tests"
        cp "${magento_tests_root}/api-functional/phpunit.xml.dist" "${magento_tests_root}/api-functional/rest.xml"
        sed -i.back "s|http://magento.url|http://${magento_host_name}|g" "${magento_tests_root}/api-functional/rest.xml"
        sed -i.back "s|http://magento-ee.localhost|http://${magento_host_name}|g" "${magento_tests_root}/api-functional/rest.xml"
        sed -i.back "s|<const name=\"TESTS_CLEANUP\" value=\"enabled\"/>|<const name=\"TESTS_CLEANUP\" value=\"disabled\"/>|g" "${magento_tests_root}/api-functional/rest.xml"
        rm -f "${magento_tests_root}/api-functional/rest.xml.back"
    fi
    if [[ ! -f "${magento_tests_root}/api-functional/soap.xml" ]] && [[ -f "${magento_tests_root}/api-functional/phpunit.xml.dist" ]]; then
        status "Creating configuration for SOAP tests"
        cp "${magento_tests_root}/api-functional/phpunit.xml.dist" "${magento_tests_root}/api-functional/soap.xml"
        sed -i.back "s|http://magento.url|http://${magento_host_name}|g" "${magento_tests_root}/api-functional/soap.xml"
        sed -i.back "s|http://magento-ee.localhost|http://${magento_host_name}|g" "${magento_tests_root}/api-functional/soap.xml"
        sed -i.back "s|<const name=\"TESTS_WEB_API_ADAPTER\" value=\"rest\"/>|<const name=\"TESTS_WEB_API_ADAPTER\" value=\"soap\"/>|g" "${magento_tests_root}/api-functional/soap.xml"
        sed -i.back "s|<const name=\"TESTS_CLEANUP\" value=\"enabled\"/>|<const name=\"TESTS_CLEANUP\" value=\"disabled\"/>|g" "${magento_tests_root}/api-functional/soap.xml"
        rm -f "${magento_tests_root}/api-functional/soap.xml.back"
    fi

    # Functional tests
    if [[ ! -f "${magento_tests_root}/functional/phpunit.xml" ]] && [[ -f "${magento_tests_root}/functional/phpunit.xml.dist" ]]; then
        status "Creating configuration for Functional tests"
        cp "${magento_tests_root}/functional/phpunit.xml.dist" "${magento_tests_root}/functional/phpunit.xml"

        # For Magento 2.0 and 2.1
        sed -i.back "s|http://localhost|http://${magento_host_name}|g" "${magento_tests_root}/functional/phpunit.xml"
        # For Magento 2.2
        sed -i.back "s|http://127.0.0.1|http://${magento_host_name}|g" "${magento_tests_root}/functional/phpunit.xml"

        sed -i.back "s|/backend/|/${magento_admin_frontname}/|g" "${magento_tests_root}/functional/phpunit.xml"
        rm -f "${magento_tests_root}/functional/phpunit.xml.back"

        if [[ ! -f "${magento_tests_root}/functional/etc/config.xml" ]] && [[ -f "${magento_tests_root}/functional/etc/config.xml.dist" ]]; then
            cp "${magento_tests_root}/functional/etc/config.xml.dist" "${magento_tests_root}/functional/etc/config.xml"
            sed -i.back "s|magento2ce.com|${magento_host_name}|g" "${magento_tests_root}/functional/etc/config.xml"
            sed -i.back "s|admin/|${magento_admin_frontname}/|g" "${magento_tests_root}/functional/etc/config.xml"
            sed -i.back "s|<backendLogin>admin</backendLogin>|<backendLogin>${magento_admin_user}</backendLogin>|g" "${magento_tests_root}/functional/etc/config.xml"
            sed -i.back "s|<backendPassword>123123q</backendPassword>|<backendPassword>${magento_admin_password}</backendPassword>|g" "${magento_tests_root}/functional/etc/config.xml"
            rm -f "${magento_tests_root}/functional/etc/config.xml.back"
        fi
    fi

    decrementNestingLevel
}

if [[ -d "${vagrant_dir}/magento2ce" ]] && [[ -d "${vagrant_dir}/magento2ee" ]]; then
    setup_test_configuration_files "${vagrant_dir}/magento2ce"
    setup_test_configuration_files "${vagrant_dir}/magento2ee"
elif [[ -d "${vagrant_dir}/magento2ce" ]]; then
    setup_test_configuration_files "${vagrant_dir}/magento2ce"
elif [[ -d "${vagrant_dir}/magento2ee" ]]; then
    setup_test_configuration_files "${vagrant_dir}/magento2ee"
else
    error "Could not configure tests No magento root directory found!"
fi

decrementNestingLevel
