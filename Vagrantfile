# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

config_file = 'config.yaml'
config = YAML.load_file("#{config_file}")

# get parameters from config file
magento_location_host = config['magento']['location']['host']
magento_location_remote = config['magento']['location']['remote']
magento_dir_name = config['magento']['dir_name']
hostname = config['env']['hostname']
memory = config['env']['memory']
ip = config['env']['ip']

magento_dir_host = magento_location_host + '/' + magento_dir_name
magento_dir_remote = magento_location_remote + '/' + magento_dir_name

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.provider "virtualbox" do |vb|
     vb.memory = memory
  end
  config.vm.network :private_network, ip: ip
  config.vm.hostname = hostname

  config.vm.synced_folder '.', '/vagrant'
  config.vm.synced_folder magento_dir_host + '/var/generation', magento_dir_remote + '/var/generation'
  config.vm.synced_folder magento_dir_host + '/app/etc', magento_dir_remote + '/app/etc'

  config.vm.provision "install_environment", type: "shell" do |s|
      s.path = "install_environment.sh"
      s.args = [magento_dir_remote]
  end

  config.vm.provision "deploy_magento_code", type: "file" do |file|
      file.source = magento_dir_host
      file.destination = magento_location_remote
  end

  config.vm.provision "install_magento", type: "shell" do |s|
      s.path = "install_magento.sh"
      s.args = [magento_dir_remote]
  end
end
