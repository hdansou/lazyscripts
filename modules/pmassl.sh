#!/bin/bash
# Installs phpMyAdmin on CentOS, RHEL

function install_phpmyadmin() {
	if [[ ${distro} = "Redhat/CentOS" ]]; then
		if [ -d /usr/share/phpMyAdmin ]; then
			echo "phpMyAdmin might be already installed! Exiting."
			exit 1
		fi
		yum -y -q install phpMyAdmin
		echo "phpMyAdmin installed."
	elif [ ${distro} == "Ubuntu" ]; then
		if [ -d /etc/phpMyAdmin ]; then
			echo "phpMyAdmin might be already installed! Exiting."
			exit 1
		fi
		export DEBIAN_FRONTEND=noninteractive
		apt-get -y -q install phpmyadmin > /dev/null 2>&1
		export DEBIAN_FRONTEND=dialog
		echo "phpMyAdmin installed."
	else
		echo "Unsupported OS. Exiting."
		exit 1
	fi
}

function add_mod_ssl() {
cat > /etc/httpd/conf.d/ssl.conf <<-EOF
LoadModule ssl_module modules/mod_ssl.so
EOF
}

function create_selfsignedcert() {
mkdir /etc/httpd/sslcerts
cd /etc/httpd/sslcerts
openssl req -new -newkey rsa:2048 -nodes -out ${IP}.csr -keyout ${IP}.key -subj "/C=US/ST=Texas/L=San Antonio/O=Rackspace Hosting/CN=${IP}"
openssl x509 -req -days 3650 -in ${IP}.csr -signkey ${IP}.key -out ${IP}.crt
}

function configure_apache() {
	if [[ ${distro} = "Redhat/CentOS" ]]; then
		mv /etc/httpd/conf.d/phpMyAdmin.conf /etc/httpd/conf.d/phpMyAdmin.conf.orig
		echo "phpMyAdmin.conf backed up to phpMyAdmin.conf.orig"
		cat > /etc/httpd/conf.d/phpMyAdmin.conf <<-EOF
		<VirtualHost ${IP}:444>
		Listen 444
		NameVirtualHost *:444
  		DocumentRoot /var/www/shtml
    	Alias /phpMyAdmin /usr/share/phpMyAdmin
    	Alias /phpmyadmin /usr/share/phpMyAdmin
    	SSLEngine on
    	SSLCertificateFile /etc/httpd/sslcerts/${IP}.crt
    	SSLCertificateKeyFile /etc/httpd/sslcerts/${IP}.key
    	<Directory /usr/share/phpMyAdmin/>
        	Order Deny,Allow
           		Deny from None
        	Allow from All
    	</Directory>

		# This directory does not require access over HTTP - taken from the original
		# phpMyAdmin upstream tarball
		#
    	<Directory /usr/share/phpMyAdmin/libraries>
        	Order Deny,Allow
        	Deny from All
        	Allow from None
    	</Directory>

		# This configuration prevents mod_security at phpMyAdmin directories from
		# filtering SQL etc.  This may break your mod_security implementation.
		#
		#    <IfModule mod_security.c>
		#        <Directory /usr/share/phpMyAdmin>
		#            SecRuleInheritance Off
		#        </Directory>
		#    </IfModule>

		</VirtualHost>
		EOF
		service httpd reload > /dev/null 2>&1
		echo "Apache restarted"
	elif [ ${distro} == "Ubuntu" ]; then
		echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf
		service apache2 reload > /dev/null 2>&1
		echo "Apache restarted"
	else
		echo "Unsupported OS. Exiting."
		exit 1
	fi
}

function openfw_port() {
iptables -I RH-Firewall-1-INPUT -p tcp -m tcp --dport 444 -m comment --comment "PMASSL" -j ACCEPT
service iptables save
}

IP=$( ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' )
echo "Beginning phpMyAdmin installation"
install_phpmyadmin
echo "Adding mod_ssl"
create_selfsignedcert
add_mod_ssl
echo "Configuring Apache"
configure_apache
echo "Opening firewall port 444"
openfw_port
echo "phpMyAdmin installation complete."
echo "phpMyAdmin is available here: https://${IP}:444/phpmyadmin"
echo "Your MySQL root credentials are:"
grep -v "client" /root/.my.cnf
exit 0