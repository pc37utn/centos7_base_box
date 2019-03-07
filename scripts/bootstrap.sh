#!/bin/bash

SHARED_DIR=$1

if [ -f "$SHARED_DIR/configs/variables" ]; then
  . "$SHARED_DIR"/configs/variables
fi

if [ ! -d "$DOWNLOAD_DIR" ]; then
  mkdir -p "$DOWNLOAD_DIR"
fi
# for setting the env variables in a non-vagrant startup
# 
touch /etc/profile.d/islandora.sh
echo "export CATALINA_HOME="$CATALINA_HOME >> /etc/profile.d/islandora.sh
echo "export FEDORA_HOME="$FEDORA_HOME >> /etc/profile.d/islandora.sh
echo "export DRUPAL_HOME="$DRUPAL_HOME >> /etc/profile.d/islandora.sh
echo "export HOME_DIR=/home/vagrant" >> /etc/profile.d/islandora.sh
echo "export SHARED_DIR=/vagrant" >> /etc/profile.d/islandora.sh
echo "export DOWNLOAD_DIR=/downloads" >> /etc/profile.d/islandora.sh
echo "export DJATOKA_HOME=/usr/local/djatoka" >> /etc/profile.d/islandora.sh
echo "export SOLR_HOME=/usr/local/solr" >> /etc/profile.d/islandora.sh
echo "export FITS_HOME=/usr/local/fits" >> /etc/profile.d/islandora.sh
echo "export FITS_VERSION=1.2.0" >> /etc/profile.d/islandora.sh

# setup timezone
sudo timedatectl set-timezone America/New_York

# disable selinux
sudo sed -i 's|SELINUX=enforcing$|SELINUX=disabled|' /etc/selinux/config
sudo touch /.autorelabel

# utilities
sudo yum -y install wget mc bzip2 zip unzip ntp psmisc

# Build tools
sudo yum -y install gcc kernel-devel kernel-headers autoconf

# add epel repo for dkms
sudo yum -y install epel-release
#sudo yum -y install dkms

# add remi repo and enable php56
sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum -y install yum-plugin-priorities
sudo yum-config-manager --enable remi-php56

# update everything
sudo yum update
# add Git vim
sudo yum -y install git vim

# add openjdk8 java and remove openjdk7
sudo yum -y install java-1.8.0-openjdk

# Java 8 (Oracle)
wget -q --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u201-b09/jdk-8u201-linux-x64.rpm
rpm -Uvh jdk-8*
rm -f jdk-8*
# make java 8 default with the alternatives command
sudo alternatives  --set java /usr/java/jdk1.8.0_201/jre/bin/java

# Set JAVA_HOME variable both now and for when the system restarts
export JAVA_HOME
JAVA_HOME=/usr/lib/jvm/java
echo "JAVA_HOME=$JAVA_HOME" >> /etc/profile.d/islandora.sh

# Maven
sudo yum -y install maven ant

# Tomcat - from the epel repo
sudo yum -y install tomcat tomcat-admin-webapps
sudo usermod -a -G tomcat vagrant
sudo systemctl enable tomcat


# More helpful packages
sudo yum -y install htop tree zsh mc

# Lamp server
sudo yum -y install mariadb-server php php-cli php-xml php-mysql httpd-devel httpd mysqlclient php-mcrypt php-mbstring
sudo systemctl enable mariadb
sudo systemctl enable httpd
sudo systemctl start mariadb
sudo systemctl start httpd

sudo usermod -a -G apache vagrant
sudo mysqladmin -u root password islandora

echo "CREATE DATABASE fedora3" | mysql -uroot -pislandora
echo "CREATE USER 'fedoraAdmin'@'localhost' IDENTIFIED BY 'fedoraAdmin'" | mysql -uroot -pislandora
echo "GRANT ALL ON fedora3.* TO 'fedoraAdmin'@'localhost'" | mysql -uroot -pislandora
echo "flush privileges" | mysql -uroot -pislandora

# Add web group, and put some users in it
sudo groupadd web
sudo usermod -a -G web apache
sudo usermod -a -G web vagrant
sudo usermod -a -G web tomcat
