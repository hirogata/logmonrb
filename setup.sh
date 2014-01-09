#!/bin/sh -x

mkdir -p /etc/logmonrb
cp ./logmon.rb /etc/logmonrb/
cp ./logmon.json /etc/logmonrb/
cp ./logmonrb /etc/init.d/

chmod 700 /etc/init.d/logmonrb
chmod 700 /etc/logmonrb/logmon.rb
chmod 600 /etc/logmonrb/logmon.json

chkconfig --add logmonrb
chkconfig --level 345 logmonrb on

