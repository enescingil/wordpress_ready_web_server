#! /bin/bash

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

#Setup a Wordpress site
function wordpress_setup(){

	#Get username
	read -p 'Please write down the username for your website: ' user_var
	#Double check the username
	echo $user_var
	read -p 'Are you sure you wanted to use that username (y/n): ' user_sure
	while [ "$user_sure" = "n" ];
	do
		read -p 'Please write down the username for your website: ' user_var
		echo $user_var
		read -p 'Are you sure you wanted to use that username (y/n): ' user_sure
	done	
	
	#Create a system user for this site
	#adduser $user_var
	#mkdir -p /home/$user_var/logs

	#Get IP Address or Host name
	read -p 'Please write down your IP Address or domain name: ' user_ip
	#Double check the IP Address
	echo $user_ip
	read -p 'Is this IP Address correct? (y/n): ' user_ip_sure
	while [ "$user_ip_sure" = "n" ];
	do
		read -p 'Please write down your IP Address or domain name: ' user_ip
		echo $user_ip
		read -p 'Is this IP Address correct? (y/n): ' user_ip_sure
	done

	#Create nginx vhost config file
	#touch $user_var.conf
	#Change it's IP Address with the given one
	sed -i 's/tutorial/'"$user_ip"'/gI' tutorial.conf
	#Paste it in to the user's config file
	mv tutorial.conf $user_var.conf
	mv $user_var.conf /etc/nginx/conf.d/
	#Disable default nginx vhost
	rm /etc/nginx/sites-enabled/default
	
	#Get the site name
	read -p 'Please write down your site name: ' user_site
	#Double check the site name
	echo $user_site
	read -p 'Is this your sitename? (y/n): ' user_site_sure
	while [ "$user_site_sure" = "n" ];
	do
		read -p 'Please write down your site name: ' user_site
		echo $user_site
		read -p 'Is this your sitename? (y/n): ' user_site_sure
	done

	#Create php-fpm vhost pool config file
	sed -i 's/tutorial/'"$user_site"'/gI' tutorial2.conf
	mv tutorial2.conf $user_var.conf
	mv $user_var.conf /etc/php/7.2/fpm/pool.d/
	#Create the php-fpm logfile
	touch /home/$user_var/logs/phpfpm_error.log

	#Create site database + DB User
	#Get the mysql_password
	

	#if [ "$user_var" = "y" ]; then
	#	echo "Thats it my boy"	
	#else
	#	read -p 'Please write down the username for your website: ' user_var
	#fi

}

#Make sure only root can run it
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as a root" 1>&2
	exit 1
else
	update
	manage_service
	nginx_conf
	php_extend
	mysql_setup
	wordpress_setup
fi
