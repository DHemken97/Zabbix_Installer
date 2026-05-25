#!/bin/bash

sudo dnf remove -y zabbix-agen*
sudo dnf remove -y zabbix-release
rm -f /etc/zabbix/zabbix-agent*.conf
rm -f /var/log/zabbix/zabbix-agent*
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/alma/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm
sudo dnf clean all
sudo dnf install -y zabbix-agent2
systemctl enable zabbix-agent2 -- now
rm -f /etc/zabbix/zabbix-agent2.conf.*