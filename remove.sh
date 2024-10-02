#!/bin/bash

cd /opt/webapp/
deactivate


systemctl stop webapp.service
systemctl disable webapp.service

systemctl stop webapp_status.timer
systemctl disable webapp_status.timer

rm -rf  /opt/webapp/

rm /etc/systemd/system/webapp_status.timer 
rm /etc/systemd/system/webapp_status.service 
rm /etc/systemd/system/webapp.service
