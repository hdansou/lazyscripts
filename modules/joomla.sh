#!/bin/bash
# Installs Joomla for a new domain
# usage ./Joomla.sh

# Get some information and set variables
function get_domain() {
	read -p "Please enter the domain name (no www): " domain
	read -p "Please enter desired SFTP username: " username
	read -p "Please enter the 10.x.x.x address of your DB Server (or use localhost): " dbhost
	read -p "Please enter desired MySQL database name: " database
	read -p "Please enter desired MySQL username: " db_user
	web_password=$( apg -m 7 -n 1 )
	db_password=$( apg -m 7 -n 1 )
	j_secret=$( apg -m 7 -n 1 )
	eth1ip=$( ifconfig eth1 | grep 'inet addr:'| cut -d: -f2 | awk '{ print $1}' )
}

# add a virtual host and restart Apache
function configure_apache() {
	if [[ $distro = "Redhat/CentOS" ]]; then
		cat > /etc/httpd/vhost.d/$domain.conf <<-EOF
		<VirtualHost *:80>
		ServerName $domain
		ServerAlias www.$domain
		DocumentRoot /var/www/vhosts/$domain
		<Directory /var/www/vhosts/$domain>
		AllowOverride All
		</Directory>
		CustomLog logs/$domain-access_log common
		ErrorLog logs/$domain-error_log
		</VirtualHost>
		EOF
		service httpd restart > /dev/null 2>&1
	elif [[ $distro = "Ubuntu" ]]; then
		cat > /etc/apache2/sites-available/$domain <<-EOF
		<VirtualHost *:80>
		ServerName $domain
		ServerAlias www.$domain
		DocumentRoot /var/www/vhosts/$domain
		<Directory /var/www/vhosts/$domain>
		AllowOverride All
		</Directory>
		CustomLog /var/log/apache2/$domain-access_log common
		ErrorLog /var/log/apache2/$domain-error_log
		</VirtualHost>
		EOF
		a2ensite $domain > /dev/null 2>&1
		service apache2 restart	 > /dev/null 2>&1
fi
}

# Fetch Joomla and extract it
# make a document root
function get_Joomla() {
	cd /root
	wget -q http://joomlacode.org/gf/download/frsrelease/15278/66554/Joomla_1.7.0-Stable-Full_Package.tar.gz
	mkdir -p /var/www/vhosts/$domain
	tar -C /var/www/vhosts/$domain -xzf Joomla_1.7.0-Stable-Full_Package.tar.gz
	rm -f /root/Joomla_1.7.0-Stable-Full_Package.tar.gz
	useradd -d /var/www/vhosts/$domain $username > /dev/null 2>&1
	echo $web_password | passwd $username --stdin > /dev/null 2>&1
}

# Set up a database locally OR show the commands to run
function configure_mysql() {
	MYSQL=$( which mysql )
	CREATE_DB="CREATE DATABASE ${database};"
	CREATE_DB_LOCAL_USER="GRANT ALL PRIVILEGES ON ${database}.* TO '${db_user}'@'${dbhost}' IDENTIFIED BY '${db_password}';"
	CREATE_DB_REMOTE_USER="GRANT ALL PRIVILEGES ON ${database}.* TO '${db_user}'@'${eth1ip}' IDENTIFIED BY '${db_password}';"
	FP="FLUSH PRIVILEGES;"
	SQL="${CREATE_DB}${CREATE_DB_LOCAL_USER}${FP}"
	if [[ $dbhost == "localhost" ]]; then
		$MYSQL -e "$SQL"
		echo "The MySQL database credentials are: "
		echo "User: ${db_user}"
		echo "Password: ${db_password}"
	else
		echo "Run these commands on your database server: "
		echo $CREATE_DB
		echo $CREATE_DB_REMOTE_USER
		echo $FP
	fi
}

# make configuration.php
function create_j_config() {
	cd /var/www/vhosts/$domain/
	touch configuration.php 
	chown -R $username: /var/www/vhosts/$domain
}

function fix_permission() {
echo "Fixing Joomla required permission and removing the installation directory"

chmod 777 administrator/components/
chmod 777 administrator/language/
chmod 777 administrator/language/en-GB/
chmod 777 administrator/language/overrides/
chmod 777 administrator/manifests/files/
chmod 777 administrator/manifests/libraries/
chmod 777 administrator/manifests/packages/
chmod 777 administrator/modules/
chmod 777 administrator/templates/
chmod 777 components/
chmod 777 images/
chmod 777 images/banners/
chmod 777 images/sampledata/
chmod 777 language/
chmod 777 language/en-GB/
chmod 777 language/overrides/
chmod 777 libraries/
chmod 777 media/
chmod 777 modules/
chmod 777 plugins/
chmod 777 plugins/authentication/
chmod 777 plugins/content/
chmod 777 plugins/editors
chmod 777 plugins/editors-xtd/
chmod 777 plugins/extension/
chmod 777 plugins/search/
chmod 777 plugins/system/
chmod 777 plugins/user/
chmod 777 templates/
chmod 777 cache/
chmod 777 administrator/cache/
chmod 777 tmp/
chmod 777 logs/
chmod 777 configuration.php
# echo "Removing the installation directory for security reason."

}
get_domain
echo "Beginning Joomla installation."
get_Joomla
echo "Joomla has been installed in /var/www/vhosts/${domain}."
create_j_config
fix_permission
configure_apache
echo "Apache has been configured for ${domain} and restarted."

configure_mysql

echo "Finalize the installation of Joomla with the following Informations."
echo "Open your browser and enter the URL http://${domain}/installation/index.php"
echo ""
echo "----------------------------SFTP Credentials--------------"
echo ""
echo "The SFTP credentials are: "
echo "User: ${username}"
echo "Password: ${web_password}"
echo "Path: /var/www/vhosts/${domain}"
echo ""
echo "----------------------------Database Credentials----------"
echo ""
echo "Database User: ${db_user}"
echo "Database Password: ${db_password}"
echo "Database Name: ${database}"
echo ""
echo "----------------------------Final Steps----------"
echo ""
echo "Remember to run this command to remove the installation directory for security reason"
echo "rm -rf /var/www/vhosts/$domain/installation/"
exit 0