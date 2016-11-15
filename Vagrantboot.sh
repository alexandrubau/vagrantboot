#!/bin/bash

# Prerequisites #
#################

# Create vagrant log directory
mkdir /var/log/vagrant

# Initialize vagrant log file variable
VLOG=/var/log/vagrant/boot.log

# Utility function to display progress
function progress {

    echo    "$1"

    echo -e "\n\n**************************************************" >> $VLOG
    echo    "* $1" >> $VLOG
    echo -e "**************************************************\n\n" >> $VLOG
}

# Add locales
echo "
LANG=\"en_US.UTF-8\"
LANGUAGE=\"en_US.UTF-8\"
LC_CTYPE=\"en_US.UTF-8\"
LC_NUMERIC=\"en_US.UTF-8\"
LC_TIME=\"en_US.UTF-8\"
LC_COLLATE=\"en_US.UTF-8\"
LC_MONETARY=\"en_US.UTF-8\"
LC_MESSAGES=\"en_US.UTF-8\"
LC_PAPER=\"en_US.UTF-8\"
LC_NAME=\"en_US.UTF-8\"
LC_ADDRESS=\"en_US.UTF-8\"
LC_TELEPHONE=\"en_US.UTF-8\"
LC_MEASUREMENT=\"en_US.UTF-8\"
LC_IDENTIFICATION=\"en_US.UTF-8\"
LC_ALL=\"en_US.UTF-8\"" >> /etc/environment

# Disable prompt
export DEBIAN_FRONTEND=noninteractive

# Update package list
apt-get update &>> $VLOG

# Git #
#######

progress "Installing Git"

# Install Git
apt-get install -y git &>> $VLOG

# Apache #
##########

progress "Installing Apache"

# Install Apache
apt-get install -y apache2 &>> $VLOG

# Disable default virtual host
a2dissite 000-default &>> $VLOG

# Create dev virtual host config
# http://www.debian-administration.org/articles/412
echo "<VirtualHost *:80>
    ServerAdmin webmaster@dev.com
    ServerName  dev.com
    ServerAlias www.dev.com

    # Indexes + Directory Root.
    DirectoryIndex index.html index.php
    DocumentRoot /vagrant/public

    <Directory /vagrant/public>
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
a2ensite 001-dev &>> $VLOG

# Enable mod_rewrite for apache
a2enmod rewrite &>> $VLOG

# MySQL #
#########

# This will answer the future questions for the wizard
# http://askubuntu.com/questions/79257/how-do-i-install-mysql-without-a-password-prompt
mysql_password='123456'
echo 'mysql-server mysql-server/root_password password '$mysql_password | debconf-set-selections # echo 'mysql-server-5.5 mysql-server/root_password password '$mysql_password | debconf-set-selections
echo 'mysql-server mysql-server/root_password_again password '$mysql_password | debconf-set-selections # echo 'mysql-server-5.5 mysql-server/root_password_again password '$mysql_password | debconf-set-selections

# Install mysql-server
apt-get install -y mysql-server &>> $VLOG

# Allow connections to this server from outside
#sed -i 's/bind-address/#bind-address/g' /etc/mysql/my.cnf

# Create new user and database devuser:devpass@devdb and allow to connect from outside and localhost
mysql --user=root --password=$mysql_password -e "CREATE DATABASE IF NOT EXISTS devdb; GRANT ALL ON devdb.* TO 'devuser'@'%' IDENTIFIED BY 'devpass'; GRANT ALL ON devdb.* TO 'devuser'@'localhost' IDENTIFIED BY 'devpass'; FLUSH PRIVILEGES;"

# PHP #
#######

progress "Installing PHP"

# Install PHP
apt-get install -y php5 php5-mysql php5-mcrypt &>> $VLOG #libapache2-mod-php5: this library is already bundeled with php5 metapackage; php5-mcrypt is required for Laravel and PHPMyAdmin

# Enable php5-mcrypt mode
php5enmod mcrypt &>> $VLOG

# Restart MySQL
service mysql restart &>> $VLOG

# PHPMyAdmin #
##############

progress "Installing PHPMyAdmin"

# This will answer the future questions for the wizard
phpmyadmin_password='654321'
echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections
echo 'phpmyadmin phpmyadmin/mysql/admin-pass password '$mysql_password | debconf-set-selections
echo 'phpmyadmin phpmyadmin/mysql/app-pass password '$phpmyadmin_password | debconf-set-selections
echo 'phpmyadmin phpmyadmin/app-password-confirm password '$phpmyadmin_password | debconf-set-selections

# Install PHPMyAdmin
apt-get install -y phpmyadmin &>> $VLOG

# Restart Apache
service apache2 restart &>> $VLOG

# Composer #
############

progress "Installing Composer"

# Download Composer Installer
php -r "readfile('https://getcomposer.org/installer');" > composer-installer.php

# Install Composer
su -c "php composer-installer.php" -l vagrant &>> $VLOG

# Remove Composer Installer
php -r "unlink('composer-installer.php');"

# Make Composer available anywhere for vagrant user
mkdir -p /home/vagrant/bin &>> $VLOG
mv composer.phar /home/vagrant/bin/composer &>> $VLOG

# Add Composer bin directory to path
echo "
# set PATH to include Composer's bin
PATH=\"\$PATH:\$HOME/.composer/vendor/bin\"" >> /home/vagrant/.profile

# NodeJS #
##########

progress "Installing Node.js"

# Run remote setup
curl -sL https://deb.nodesource.com/setup_5.x | bash - &>> $VLOG

# Install NodeJS
apt-get install -y nodejs &>> $VLOG

# Laravel #
############

#progress "Installing Laravel"

# Install Laravel
#su -c "composer global require \"laravel/installer\"" -l vagrant &>> $VLOG

# Configure #
#############

progress "Preparing application"

# Install app dependencies
su -c "cd /vagrant && composer install" -l vagrant &>> $VLOG
su -c "cd /vagrant && npm install" -l vagrant &>> $VLOG

# Copy app environment file
cp /vagrant/.env.example /vagrant/.env

# Set app environment file variables
sed -i 's/DB_DATABASE=homestead/DB_DATABASE=devdb/g' /vagrant/.env
sed -i 's/DB_USERNAME=homestead/DB_USERNAME=devuser/g' /vagrant/.env
sed -i 's/DB_PASSWORD=secret/DB_PASSWORD=devpass/g' /vagrant/.env

# Optimize app
su -c "cd /vagrant && php artisan optimize" -l vagrant &>> $VLOG

# Generate key
su -c "cd /vagrant && php artisan key:generate" -l vagrant &>> $VLOG

# Migrate database
su -c "cd /vagrant && php artisan migrate" -l vagrant &>> $VLOG

# Done #
########

progress "Ready!"
