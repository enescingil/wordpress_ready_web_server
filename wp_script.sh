#! /bin/bash

#Make sure only root can run it
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as a root" 1>&2
	exit 1
else

fi

#Installing required software for our hosting platform.
function update(){

	apt-get update -y -V
	apt-get install mysql-server
	apt-get install php-mysql php-fpm monit
	
	#install nginx custom repository(PPA)
	add-apt-repository ppa:nginx/stable
	apt-get update
	apt-get install nginx
	apt-get autoclean
}

#Managing services with systemd
function manage_service(){

	sudo systemctl start nginx php7.2-fpm monit
	sudo systemctl enable mysql nginx php7.2-fpm monit

}

#Basic nginx configuration
function nginx_conf(){
#Rename and backup the original configuration file
	mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.ORIGIN
	#Move the configured nginx file to the original location
	mv nginx.conf /etc/nginx/
	#Now create the cache directory
	mkdir -p /usr/share/nginx/cache/fgi
	#Check for configuration errors
	nginx -t
	sleep 5
	systemctl reload nginx

}

#Basic php-fpm and PHP configuration
function php_extend(){

	apt-get install php-json php-xmlrpc php-curl php-gd php-xml php-mbstring
	#Now ensure that the directory for php-fpn sockets exist
	mkdir /var/run/php-fpm
	#Backup the PHP config files
	mv /etc/php/7.2/fpm/php-fpm.conf /etc/php/7.2/fpm/php-fpm.conf.ORIG
	#Copy the new php-fpm file
	mv php-fpm.conf /etc/php/7.2/fpm
	#Remove the original pool
	rm /etc/php/7.2/fpm/pool.d/www.conf
	#Copy the new pool conf file
	mv www.conf /etc/php/7.2/fpm
	#Backup the php.ini file
	mv /etc/php/7.2/fpm/php.ini /etc/php/7.2/fpm/php.ini.ORIG
	#Copy the php.ini file
	mv php.ini /etc/php/7.2/fpm/
	#Restart the php-fpm
	systemctl restart php7.2-fpm
}

#Mysql setup
function mysql_setup(){

	#Start the setup
	/usr/bin/mysql_secure_installation
	#Restart the mysql
	systemctl restart mysql
}
