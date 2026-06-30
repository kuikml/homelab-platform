#!/bin/bash
set -e

echo "=== 1. Waiting for cloud-init to finish ==="
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
    echo "Waiting for cloud-init to finish..."
    sleep 2
done

echo "=== 2. Installing unattended-upgrades ==="
sudo apt-get update
sudo apt-get install -y unattended-upgrades

echo "=== 3. Configuring unattended-upgrades ==="
sudo systemctl enable --now unattended-upgrades

echo "=== 4. SSH hardening ==="
sudo mkdir -p /etc/ssh/sshd_config.d
sudo tee /etc/ssh/sshd_config.d/hardening.conf <<EOF
# Disable root login
PermitRootLogin no
# Disable password authentication
PasswordAuthentication no
EOF
sudo chmod 644 /etc/ssh/sshd_config.d/hardening.conf
sudo systemctl restart sshd

echo "=== 5. Moving config file for PVE ==="
sudo cp /tmp/00-pve.cfg /etc/cloud/cloud.cfg.d/00-pve.cfg

echo "=== 6. Cleaning up ==="
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
sudo journalctl --vacuum-time=1d
sudo find /var/log -type f -name "*.log" -exec sudo truncate -s 0 {} \;
sudo rm -f /etc/ssh/ssh_host_*
sudo truncate -s 0 /etc/machine-id
sudo apt-get -y autoremove --purge
sudo apt-get -y clean
sudo apt-get -y autoclean

echo "=== 7. Cleaning cloud-init data ==="
sudo cloud-init clean
sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
sudo rm -f /etc/netplan/00-installer-config.yaml

echo "=== 8. Synchronizing filesystem ==="
sudo sync

echo "=== Cleanup and hardening complete ==="
