#!/bin/bash

apt update
apt install python3 python3-venv python3-pip

mkdir -p /opt/webapp
chown $USER:$USER /opt/webapp

sudo cp ${PWD}/app.py /opt/webapp/
sudo cp ${PWD}/webapp.service /etc/systemd/system/
sudo cp ${PWD}/webapp_status.timer /etc/systemd/system/
sudo cp ${PWD}/webapp_status.service /etc/systemd/system/
sudo cp ${PWD}/check_status.py /opt/webapp/

cd /opt/webapp/

python3 -m venv appvenv
source appvenv/bin/activate

pip install flask
pip install requests

systemctl start webapp.service
systemctl enable webapp.service
systemctl start webapp_status.timer
systemctl enable webapp_status.timer

