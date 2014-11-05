#!/usr/bin/env bash

########################
#       General        #
########################

# Enter in root account
sudo su

# Surpress the locale enviroment error
export LC_ALL="en_US.UTF-8"
echo 'LC_ALL="en_US.UTF-8"' >> /etc/environment
export LANGUAGE="en_US:en"
echo 'LANGUAGE="en_US:en"' >> /etc/environment
locale-gen en_US en_US.UTF-8
dpkg-reconfigure locales

# Set this variable because we don't want to pe prompted with fields
export DEBIAN_FRONTEND=noninteractive

# Update sources
apt-get update

# Install base software - Some of the base software is already instaled in Ubuntu Server (trusty) 14.04
#apt-get install -y vim 
apt-get install -y mc
#apt-get install -y curl
apt-get install -y git # this is required for Composer to install dependencies
#apt-get install -y debconf-utils # this is required for preconfiguring fields when prompted - this is already installed

########################
#        Apache        #
########################

# Install apache2
apt-get install -y apache2

# Disable default virtual host
a2dissite 000-default

# Create dev virtual host config
# http://www.debian-administration.org/articles/412
echo "<VirtualHost *:80>
    ServerAdmin webmaster@dev.com
    ServerName  dev.com
    ServerAlias www.dev.com

    # Indexes + Directory Root.
    DirectoryIndex index.html index.php
    DocumentRoot /vagrant/

    # Rewrite
    <Directory /vagrant/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Possible values include: debug, info, notice, warn, error, crit, alert, emerg.
    #LogLevel warn

    # Logfiles
    #ErrorLog  /vagrant/apache2.error.log
    #CustomLog /vagrant/apache2.access.log combined
</VirtualHost>" > /etc/apache2/sites-available/001-dev.conf

# Enable de virtual host
a2ensite 001-dev

# Enable mod_rewrite for apache
a2enmod rewrite

########################
#         MySQL        #
########################

# This will answer the future questions for the wizard
# http://askubuntu.com/questions/79257/how-do-i-install-mysql-without-a-password-prompt
mysql_password='123456'
echo 'mysql-server mysql-server/root_password password '$mysql_password | debconf-set-selections # echo 'mysql-server-5.5 mysql-server/root_password password '$mysql_password | debconf-set-selections
echo 'mysql-server mysql-server/root_password_again password '$mysql_password | debconf-set-selections # echo 'mysql-server-5.5 mysql-server/root_password_again password '$mysql_password | debconf-set-selections

# Install mysql-server
apt-get install -y mysql-server

# Allow connections to this server from outside
#sed -i 's/bind-address/#bind-address/g' /etc/mysql/my.cnf

# Create new user and database devuser:devpass@devdb and allow to connect from outside and localhost
#mysql --user=root --password=$mysql_password -e "CREATE DATABASE IF NOT EXISTS devdb; GRANT ALL ON devdb.* TO 'devuser'@'%' IDENTIFIED BY 'devpass'; GRANT ALL ON devdb.* TO 'devuser'@'localhost' IDENTIFIED BY 'devpass'; FLUSH PRIVILEGES;"

########################
#         PHP5         #
########################

# Install php5
apt-get install -y php5 php5-mysql php5-mcrypt # libapache2-mod-php5 - this library is bundeled with php5 metapackage; php5-mcrypt is required for Laravel and PHPMyAdmin

# Enable php5-mcrypt mode
php5enmod mcrypt

# Restart mysql service
service mysql restart

########################
#      PHPMyAdmin      #
########################

# This will answer the future questions for the wizard
phpmyadmin_password='654321'
echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections
echo 'phpmyadmin phpmyadmin/mysql/admin-pass password '$mysql_password | debconf-set-selections
echo 'phpmyadmin phpmyadmin/mysql/app-pass password '$phpmyadmin_password | debconf-set-selections
echo 'phpmyadmin phpmyadmin/app-password-confirm password '$phpmyadmin_password | debconf-set-selections

# Install PHPMyAdmin
apt-get install -y phpmyadmin

# Restart apache2 to reload the configuration
service apache2 restart

# Install Composer
#curl -sS https://getcomposer.org/installer | php
#mv composer.phar /usr/local/bin/composer

# Add RO language because PHP needs to know how to sort special characters
#locale-gen ro_RO
#locale-gen ro_RO.UTF-8

# List all the available languages in the system
#locale -a

# Install NodeJS from repo
#apt-get install -y python-software-properties python g++ make
#add-apt-repository -y ppa:chris-lea/node.js
#apt-get update
#apt-get install -y nodejs

# Install Git because SailsJS needs it
#apt-get install -y git-core

# Install SailsJS
#npm -g install sails

# Create Sencha directory, and children
#mkdir /opt/Sencha
#mkdir /opt/Sencha/ExtJS
#mkdir /opt/Sencha/Cmd

# Get Sencha ExtJS SDK and place it in temporary folder
#wget http://cdn.sencha.com/ext/gpl/ext-4.2.1-gpl.zip -P /tmp/

# Unzip Sencha ExtJS SDK
#unzip /tmp/ext-4.2.1-gpl.zip -d /opt/Sencha/ExtJS/

# Get Sencha Cmd and place it in temporary folder
#wget http://cdn.sencha.com/cmd/4.0.1.45/SenchaCmd-4.0.1.45-linux.run.zip -P /tmp/

# Unzip Sencha Cmd in the same directory
#unzip /tmp/SenchaCmd-4.0.1.45-linux.run.zip

# Install Java Runtime Enviorment from repo
#add-apt-repository -y ppa:webupd8team/java
#apt-get update
#apt-get install -y oracle-java7-installer

