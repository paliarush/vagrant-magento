# Vagrant project for Magento 2 developers (optimized for Mac, Windows and \*nix hosts)

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Semver](http://img.shields.io/SemVer/2.0.0.png?color=blue)](http://semver.org/spec/v2.0.0.html)
[![Latest GitHub release](docs/images/release_badge.png)](https://github.com/paliarush/magento2-vagrant-for-developers/releases/latest)

 * [What You get](#what-you-get)
 * [How to install](#how-to-install)
   * [Requirements](#requirements)
   * [Installation steps](#installation-steps)
   * [Default credentials and settings](#default-credentials-and-settings)
   * [Getting updates and fixes](#getting-updates-and-fixes)
 * [Day-to-day development scenarios](#day-to-day-development-scenarios)
   * [Reinstall Magento](#reinstall-magento)
   * [Clear magento cache](#clear-magento-cache)
   * [Update composer dependencies](#update-composer-dependencies)
   * [Switch between CE and EE](#switch-between-ce-and-ee)
   * [Debugging with XDebug](#debugging-with-xdebug)
   * [Multiple Magento instances](#multiple-magento-instances)

## What You get

It is expected that Magento 2 project source code will be located and managed on the host. This is necessary to allow quick indexing of project files by IDE. All other infrastructure is deployed on the guest machine.

Current Vagrant configuration aims to solve performance issues of Magento installed on Virtual Box **for development**. Custom solution is implemented for Windows hosts. See [explanation of the proposed solution](docs/performance-issue-on-windows-hosts.md).

Environment for Magento EE development is configured as well.

It is easy to [install multiple Magento instances](#multiple-magento-instances) based on different codebases simultaneously.

[Project initialization script](init_project.sh) configures complete development environment:

 1. Adds some missing software on the host
 1. Configures all software necessary for Magento 2 using [custom Ubuntu vagrant box](https://atlas.hashicorp.com/paliarush/boxes/magento2.ubuntu) (Apache 2.4, PHP 7.0 (or 5.5.9), MySQL 5.6, Git, Composer, XDebug, Rabbit MQ)
 1. Installs Magento 2
 1. Configures PHP Storm project (partially at the moment)

## How to install

If you never used Vagrant before, read [Vagrant Docs](https://docs.vagrantup.com/v2)

### Requirements

Software listed below should be available in [PATH](https://en.wikipedia.org/wiki/PATH_\(variable\)) (except for PHP Storm).

- [Vagrant 1.8+](https://www.vagrantup.com/downloads.html)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git). Make sure you have SSH keys generated and associated with your github account, see [how to check](https://help.github.com/articles/testing-your-ssh-connection/) and [how to configure](https://help.github.com/articles/generating-ssh-keys/) if not configured.<br />
:information_source: It is possible to use another way of getting codebase instead of cloning, it does not matter for successful installation. Just put Magento 2 codebase inside of `vagrant-magento/magento2ce`.<br />
:information_source: ![](docs/images/windows-icon.png) On Windows hosts Git must be [v2.7+](http://git-scm.com/download/win), also make sure to set the following options to avoid issues with incorrect line separators:

    ```
    git config --global core.autocrlf false
    git config --global core.eol LF
    git config --global diff.renamelimit 5000
    ```
- ![](docs/images/linux-icon.png)![](docs/images/osx-icon.png) [PHP](http://php.net/manual/en/install.php) (any version) to allow Magento dependency management with [Composer](https://getcomposer.org/doc/00-intro.md)
- [PHP Storm](https://www.jetbrains.com/phpstorm) is optional but recommended.
- ![](docs/images/linux-icon.png)![](docs/images/osx-icon.png) [NFS server](https://en.wikipedia.org/wiki/Network_File_System) must be installed and running on \*nix and OSX hosts. Is usually available, so just try to follow [installation steps](#how-to-install) first.

### Installation steps
 
 1. Open terminal and change directory to the one which you want to contain Magento project. ![](docs/images/windows-icon.png) On Windows use Git Bash, which is available after Git installation

 1. Download project with Vagrant configuration:
 
   ```
   git clone git@github.com:paliarush/magento2-vagrant-for-developers.git vagrant-magento
   ```
 
 1. Copy [etc/composer/auth.json.dist](etc/composer/auth.json.dist) to `etc/composer/auth.json`

 1. Optionally, copy [etc/config.yaml.dist](etc/config.yaml.dist) as `etc/config.yaml` and make necessary customizations
 
 1. Initialize project, configure environment, install Magento, configure PHPStorm project:
 
   ```
   cd vagrant-magento
   bash init_project.sh
   ```
   
   :information_source: ![](docs/images/linux-icon.png)![](docs/images/osx-icon.png) On OSX and \*nix hosts NFS will be used by default to sync your project files with guest. On some hosts Vagrant cannot configure NFS properly, in this case it is possible to deploy project without NFS by setting `use_nfs` option in [config.yaml](etc/config.yaml.dist) to `0` <br />
   :information_source: ![](docs/images/windows-icon.png) On Windows hosts you might face `Composer Install Error: ZipArchive::extractTo(): Full extraction path exceed MAXPATHLEN (260)` exception during `composer install`. This can be fixed in 2 ways: decrease path length to the project directory or set `composer_prefer_source` option in [config.yaml](etc/config.yaml.dist) to `1`

 1. Use `vagrant-magento` directory as project root in PHP Storm (not `vagrant-magento/magento2ce`). This is important, because in this case PHP Storm will be configured automatically by [init_project.sh](init_project.sh). If NFS files sync is disabled in [config](etc/config.yaml.dist) and ![](docs/images/windows-icon.png) on Windows hosts [verify deployment configuration in PHP Storm](docs/phpstorm-configuration-windows-hosts.md)

### Default credentials and settings

Some of default settings are available for override. These settings can be found in the file [etc/config.yaml.dist](etc/config.yaml.dist).
To override settings just create a copy of the file under the name 'config.yaml' and put there your custom settings.
When using [init_project.sh](init_project.sh), if not specified manually, random IP address is generated and is used as suffix for host name to prevent collisions, in case when 2 or more instances are running at the same time.
Upon a successful installation, you'll see the location and URL of the newly-installed Magento 2 application in console.

**Web access**:
- Access storefront at `http://magento2.vagrant<random_suffix>`
- Access admin panel at `http://magento2.vagrant<random_suffix>/admin/`
- Magento admin user/password: `admin/123123q`
- Rabbit MQ control panel: `http://magento2.vagrant<random_suffix>:15672`, credentials `guest`/`guest`

**Codebase and DB access**:
- Path to your Magento installation on the VM:
  - Can be retrieved from environment variable: `echo ${MAGENTO_ROOT}`
  - ![](docs/images/windows-icon.png) On Windows hosts: `/var/www/magento2ce`
  - ![](docs/images/linux-icon.png)![](docs/images/osx-icon.png) On Mac and \*nix hosts: the same as on host
- MySQL DB host: `localhost` (not accessible remotely)
- MySQL DB name: `magento`, `magento_integration_tests`
- MySQL DB user/password: just use `mysql` with no user and password (`root/password` will be used by default)

**Codebase on host**
- CE codebase: `vagrant_project_root/magento2ce`
- EE codebase will be available if path to EE repository is specified in `etc/config.yaml`: `vagrant_project_root/magento2ce/magento2ee`

### Getting updates and fixes

Current vagrant project follows [semantic versioning](http://semver.org/spec/v2.0.0.html) so feel free to pull the latest features and fixes, they will not break your project.
For example your current branch is `2.0`, then it will be safe to pull any changes from `origin/2.0`. However branch `3.0` will contain changes backward incompatible with `2.0`.
Note, that semantic versioning is only used for `x.0` branches (not for `develop`).

## Day-to-day development scenarios
    
### Reinstall Magento
To save some time and get clear Magento installation, you can skip installation of software like web server or php.
The following command will clear Magento DB, Magento caches and reinstall Magento instance.

Go to 'vagrant-magento' created earlier and run in command line:

```
bash m-reinstall
```

### Clear magento cache

Go to 'vagrant-magento' created earlier and run in command line:

```
bash m-clear-cache
```

### Switch between CE and EE

Assume, that EE codebase is available in `vagrant_project_root/magento2ce/magento2ee`.
The following commands will link/unlink EE codebase, clear cache, update composer dependencies and reinstall Magento.
Go to 'vagrant-magento' created earlier and run in command line:

```
bash m-switch-to-ce
OR
bash m-switch-to-ee
```

### Update composer dependencies

Go to 'vagrant-magento' created earlier and run in command line:

```
bash m-composer install
OR
bash m-composer update
```

### Debugging with XDebug

XDebug is already configured to connect to the host machine automatically. So just:
 
 1. Set XDEBUG_SESSION=1 cookie (e.g. using 'easy Xdebug' extension for Firefox). See [XDebug documentation](http://xdebug.org/docs/remote) for more details
 1. Start listening for PHP Debug connections in PhpStorm on default 9000 port. See how to [integrate XDebug with PhpStorm](https://www.jetbrains.com/phpstorm/help/configuring-xdebug.html#integrationWithProduct)
 1. Set beakpoint or set option in PhpStorm menu 'Run -> Break at first line in PHP scripts'
 
### Multiple Magento instances
 
To install several Magento instances based on different code bases, just follow [Installation steps](#installation-steps) to initialize project in another directory on the host.
Unique IP address, SSH port and domain name will be generated for each new instance if not specified manually in `etc/config.yaml`
