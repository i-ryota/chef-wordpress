#
# Cookbook Name:: test
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute

# install package
%w{
 httpd
 mysql-server
 php
 php-mysql
}.each do |pkg|
  package pkg do
    action :install
  end
end

# overrite php.ini
cookbook_file "/etc/php.ini" do
  source "php.ini"
  owner "root"
  group "root"
  mode 0644
end

# overwite httpd.conf
template "/etc/httpd/conf/httpd.conf" do
  source "httpd.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

# service setting httpd
service "httpd" do
  supports [:restart, :reload, :status]
  action :enable
end

# service setting mysqld
service "mysqld" do
  supports [:restart, :reload, :status]
  action [:enable, :start]
end

# create wordpress DB
execute "create database" do
  command "/usr/bin/mysqladmin -u root create #{node['mysql']['db']}"
  not_if "/usr/bin/mysql -u root -e 'show databases;' | grep #{node['mysql']['db']}"
end

# copy SQL File to /tmp
template "/tmp/grants.sql" do
  source "grants.sql.erb"
  owner "root"
  group "root"
  mode 0600
end

# create DB user
execute "create database user" do
  command "/usr/bin/mysql -u root < /tmp/grants.sql"
end

# get wordress
remote_file "/tmp/wordpress.tar.gz" do
  source "http://ja.wordpress.org/wordpress-3.7.1-ja.tar.gz"
  owner "root"
  group "root"
  mode 0644
  action :create_if_missing
end

# install wordpress
execute "install wordpress" do
  command "tar zxvf /tmp/wordpress.tar.gz -C #{node['wordpress']['insdir']}"
  not_if{::Dir.exists?("#{node['wordpress']['home']}")}
end

directory "#{node['wordpress']['home']}" do
  owner "apache"
  group "apache"
end

# copy initial setting
template "#{node['wordpress']['home']}wp-config.php" do
  source "wp-config.php.erb"
  owner "apache"
  group "apache"
  mode 0666
end

service "httpd" do
  action :restart
end

service "iptables" do
  action :stop
end


