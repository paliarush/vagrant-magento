# -*- mode: ruby -*-
# vi: set ft=ruby :

# Method for reading values from local config
def get_variable_value(variable_name)
   custom_value_path = Dir.pwd + '/local.config/' + variable_name + '.txt'
   default_value_path = Dir.pwd + '/local.config/' + variable_name + '.txt.dist'
   if File.exist?(custom_value_path)
      return File.read(custom_value_path)
   else
       return File.read(default_value_path)
   end
end

module OS
    def OS.is_windows
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end
end

host_magento_dir = Dir.pwd + '/magento2ce'
magento_host_name = get_variable_value('magento_host_name')
magento_ip_address = get_variable_value('magento_ip_address')

VAGRANT_API_VERSION = 2
Vagrant.configure(VAGRANT_API_VERSION) do |config|
    #config.vm.box = "centos/7"
    config.vm.box = "puppetlabs/centos-7.2-64-nocm"

    config.vm.provider "virtualbox" do |vb|
        vb.memory = get_variable_value('guest_ram') # Default is 2Gb, around 3Gb is necessary to run functional tests
    end

    config.vm.synced_folder '.', '/vagrant', disabled: true
    config.vm.synced_folder './local.config', '/vagrant/local.config'
    config.vm.synced_folder './scripts', '/vagrant/scripts'
    if OS.is_windows
        guest_magento_dir = '/var/www/magento2ce'
        config.vm.synced_folder host_magento_dir + '/var/generation', guest_magento_dir + '/var/generation'
        config.vm.synced_folder host_magento_dir + '/app/etc', guest_magento_dir + '/app/etc'
    else
        guest_magento_dir = host_magento_dir
        config.vm.synced_folder host_magento_dir, guest_magento_dir, type: "nfs"
    end

    shell_script_args = [
        OS.is_windows ? "1" : "0",
        guest_magento_dir,
        magento_host_name
    ]
    config.vm.provision "install_centos7_env", type: "shell" do |s|
        s.path = "scripts/provision/install_centos7_env.sh"
        s.args = shell_script_args
    end

    if OS.is_windows
        config.vm.provision "deploy_magento_code", type: "file", source: host_magento_dir, destination: '/var/www'
    end

    config.vm.provision "install_magento", type: "shell" do |s|
        s.path = "scripts/provision/install_magento.sh"
        s.args = shell_script_args
    end

    # Host manager plugin configuration
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true
    config.vm.define magento_host_name do |node|
        node.vm.hostname = magento_host_name
	node.vm.network "forwarded_port", guest: 80, host: 8080
        node.vm.network :private_network, ip: magento_ip_address
    end
end
