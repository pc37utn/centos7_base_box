#!/bin/bash

echo "Installing Drupal."

SHARED_DIR=$1

if [ -f "$SHARED_DIR/configs/variables" ]; then
  . "$SHARED_DIR"/configs/variables
fi

# Apache configuration file
#export APACHE_CONFIG_FILE=/etc/apache2/sites-enabled/000-default.conf
export APACHE_CONFIG_FILE=/etc/httpd/conf/httpd.conf


# Drush and drupal deps
yum -y install php-gd php-devel php-xml php-soap php-curl
yum -y install php-pecl-imagick ImageMagick perl-Image-Exiftool bibutils poppler-utils
pecl install uploadprogress
sed -i '/; extension_dir = "ext"/ a\ extension=uploadprogress.so' /etc/php.ini
# drush 8.1 from rhel
yum -y install drush
#yum -y install mod_rewrite

# copy pre-made httpd.conf
cp -v "$SHARED_DIR"/configs/httpd.conf /etc/httpd/conf/httpd.conf
# remove the default index.html
rm /var/www/html/index.html

# Cycle apache
systemctl restart httpd

cd /var/www

# Download Drupal
drush dl drupal-7.x --drupal-project-rename=drupal

# Permissions
chown -R apache:apache drupal
chmod -R g+w drupal

# Do the install
cd drupal
drush si -y --db-url=mysql://root:islandora@localhost/drupal7 --site-name=islandora-development.org
drush user-password admin --password=islandora


# Cycle apache
systemctl restart httpd

# Make the modules directory
if [ ! -d sites/all/modules ]; then
  mkdir -p sites/all/modules
fi
cd sites/all/modules

# Modules
drush dl devel imagemagick ctools jquery_update pathauto xmlsitemap views variable token libraries datepicker date
drush -y en devel imagemagick ctools jquery_update pathauto xmlsitemap views variable token libraries datepicker_views

drush dl coder-7.x-2.5
drush -y en coder

# php.ini templating
cp -v "$SHARED_DIR"/configs/php.ini /etc/php.ini

systemctl restart httpd

# sites/default/files ownership
chown -hR apache:apache "$DRUPAL_HOME"/sites/default/files

# Run cron
cd "$DRUPAL_HOME"/sites/all/modules
drush cron
