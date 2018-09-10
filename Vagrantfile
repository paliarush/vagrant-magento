# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 1.8"

require 'yaml'

include Vagrant::Util

module Config
    # Load and override config settings
    def self.load
        local_config_dir = 'etc'
        config_dist_file = local_config_dir + '/config.yaml.dist'
        config_file = local_config_dir + '/config.yaml'

        config_data_dist = YAML.load_file(config_dist_file)
        config_data = File.exists?(config_file) ? YAML.load_file(config_file) : {}
        return DeepMerge.deep_merge(config_data_dist, config_data)
    end
end

# Get parameters from config file
config_data = Config.load
magento_host_name = config_data['magento']['host_name']
magento_ip_address = config_data['guest']['ip_address']
forwarded_ssh_port = config_data['guest']['forwarded_ssh_port']
guest_memory = config_data['guest']['memory']
guest_cpus = config_data['guest']['cpus']

# NFS will be used for *nix and OSX hosts, if not disabled explicitly in config
use_nfs_for_synced_folders = !Platform.windows? && (config_data['guest']['use_nfs'] == 1)

host_vagrant_dir = Dir.pwd + ''
host_magento_dir = host_vagrant_dir + '/magento2ce'

Vagrant.configure(vagrant_config_version = "2") do |config|
    config.vm.box = "paliarush/magento2.ubuntu"
    config.vm.box_version = "~> 1.1"

    config.vm.provider "virtualbox" do |vb|
        vb.memory = guest_memory
        vb.cpus = guest_cpus
        # Uncomment option below to avoid issues with VirtualBox on Windows 10
        # vb.gui=true
    end

    config.vm.synced_folder '.', '/vagrant', disabled: true
    config.vm.synced_folder './etc', '/vagrant/etc', mount_options: ["dmode=775,fmode=664"]
    config.vm.synced_folder './scripts', '/vagrant/scripts'
    config.vm.synced_folder './log', '/vagrant/log'
    config.vm.synced_folder './.idea', '/vagrant/.idea', create: true
    if use_nfs_for_synced_folders
        guest_magento_dir = host_magento_dir
        config.vm.synced_folder host_magento_dir, guest_magento_dir, type: "nfs", create: true
    else
        guest_magento_dir = '/var/www/magento2ce'
        config.vm.synced_folder host_magento_dir + '/var', guest_magento_dir + '/var', create: true
        config.vm.synced_folder host_magento_dir + '/generated', guest_magento_dir + '/generated', create: true
        config.vm.synced_folder host_magento_dir + '/app/etc', guest_magento_dir + '/app/etc', create: true
    end

    shell_script_args = [
        use_nfs_for_synced_folders ? "1" : "0",       #1
        guest_magento_dir,                            #2
        magento_host_name,                            #3
        config_data['environment']['use_php7'] || 0,  #4 TODO: Remove legacy parameter, replaced with php_version
        host_magento_dir,                             #5
        Platform.windows? ? "1" : "0",                    #6
        host_vagrant_dir,                             #7
        config_data['environment']['php_version']     #8
    ]

    config.vm.provision "fix_no_tty", type: "shell", run: "always" do |s|
        s.privileged = false
        s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
    end

    config.vm.provision "upgrade_environment_recurring", type: "shell", run: "always", keep_color: true do |s|
        s.path = "scripts/provision/upgrade_environment_recurring.sh"
        s.args = shell_script_args
    end

    config.vm.provision "configure_environment", type: "shell", keep_color: true do |s|
        s.path = "scripts/provision/configure_environment.sh"
        s.args = shell_script_args
    end

    config.vm.provision "configure_environment_recurring", type: "shell", run: "always", keep_color: true do |s|
        s.path = "scripts/provision/configure_environment_recurring.sh"
        s.args = shell_script_args
    end

    config.vm.provision "export_env_variables_recurring", type: "shell", run: "always", keep_color: true do |s|
        s.path = "scripts/provision/export_env_variables_recurring.sh"
        s.args = shell_script_args
    end

    if !use_nfs_for_synced_folders
        config.vm.provision "host_compress_magento_code", type: "host_shell", inline: "tar cf scripts/host/magento2ce.tar magento2ce"
        config.vm.provision "guest_uncompress_magento_code", type: "shell", inline: "mkdir -p /var/www && tar xf /vagrant/scripts/host/magento2ce.tar -C /var/www &>/dev/null"
        config.vm.provision "guest_remove_compressed_code", type: "shell", inline: "rm -f /vagrant/scripts/host/magento2ce.tar"
    end

    # Host manager plugin configuration
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.hostmanager.include_offline = true
    config.vm.define magento_host_name do |node|
        node.vm.hostname = magento_host_name
        node.vm.network :private_network, ip: magento_ip_address
        node.vm.network :forwarded_port, guest: 22, host: forwarded_ssh_port
    end
    config.ssh.guest_port = forwarded_ssh_port
end
