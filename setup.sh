#!/bin/sh -x

mkdir -p /etc/logmon
cp ./logmon.rb /etc/logmon/
cp ./logmon.conf /etc/logmon/
cp ./logmon /etc/init.d/logmon

chmod 700 /etc/init.d/logmon
chmod 700 /etc/logmon/logmon.rb
chmod 600 /etc/logmon/logmon.conf

chkconfig --add logmon
chkconfig --level 345 logmon on

