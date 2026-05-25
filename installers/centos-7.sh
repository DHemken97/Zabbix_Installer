#!/bin/bash

sudo dnf remove -y zabbix-agen*
sudo dnf remove -y zabbix-release
rm -f /etc/zabbix/zabbix-agent*.conf
rm -f /var/log/zabbix/zabbix-agent*
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rhel/7/x86_64/zabbix-release-latest-7.0.el7.noarch.rpm
sudo yum clean all
sudo yum install -y zabbix-agent2
systemctl enable zabbix-agent2 -- now
rm -f /etc/zabbix/zabbix-agent2.conf.*