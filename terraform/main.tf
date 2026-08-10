resource "proxmox_vm_qemu" "k3s_master" {
  name   = "k3s-master-01"
  target_node = "proxmox"
  vmid   = 301

  clone  = "ubuntu-22.04-template"
  full_clone = true

  cores  = 2
  memory = 2048
  agent = 1

  boot = "order=virtio0"
   bootdisk = "virtio0"
  disks {
    virtio {
        virtio0 {
            disk {
                size = "30G"
                storage = "local-zfs"
            }
        }
    }
    ide {
        ide3 {
            cloudinit {
                storage = "local-zfs"
            }
        }
    }
  }

  network {
    id = 0
    model = "virtio"
    bridge = "vmbr0"
  }

  os_type = "cloud-init"
  ipconfig0 = "ip=192.168.1.151/24,gw=192.168.1.1"
  sshkeys = var.ssh_public_key
  
}

resource "proxmox_vm_qemu" "k3s_workers" {
  count = 2
  name   = "k3s-worker-0${count.index + 1}"
  target_node = "proxmox"
  vmid   = 304 + count.index

  clone  = "ubuntu-22.04-template"
  full_clone = true

  cores  = 2
  memory = 2048
  agent = 1

  boot = "order=virtio0"
   bootdisk = "virtio0"
  disks {
    virtio {
        virtio0 {
            disk {
                size = "30G"
                storage = "local-zfs"
            }
        }
    }
    ide {
        ide3 {
            cloudinit {
                storage = "local-zfs"
            }
        }
    }
  }

  network {
    id = 0
    model = "virtio"
    bridge = "vmbr0"
  }

  os_type = "cloud-init"
  ipconfig0 = "ip=192.168.1.${count.index + 152}/24,gw=192.168.1.1"
  sshkeys = var.ssh_public_key
}

resource "proxmox_vm_qemu" "vpn_node" {
  name   = "vpn-strongswan"
  target_node = "proxmox"
  vmid   = 311

  clone  = "ubuntu-22.04-template"
  full_clone = true

  cores  = 1
  memory = 1024
  agent = 1

  boot = "order=virtio0"
  bootdisk = "virtio0"
  disks {
    virtio {
        virtio0 {
            disk {
                size = "30G"
                storage = "local-zfs"
            }
        }
    }
    ide {
        ide3 {
            cloudinit {
                storage = "local-zfs"
            }
        }
    }
  }

  network {
    id = 0
    model = "virtio"
    bridge = "vmbr0"
  }

  os_type = "cloud-init"
  ipconfig0 = "ip=192.168.1.160/24,gw=192.168.1.1"
  sshkeys = var.ssh_public_key
}


# ======================================
# MAPPING HOSTS TO ANSIBLE INVENTORY
# ======================================

# 1. Master node
resource "ansible_host" "k3s_master" {
  name = proxmox_vm_qemu.k3s_master.name
  groups = ["master", "kubernetes"]

  variables = {
    ansible_host = split("/", split("ip=", proxmox_vm_qemu.k3s_master.ipconfig0)[1])[0]
    ansible_user = "ubuntu"
    node_role = "master"
    node_blueprint = "kubernetes"
  }
}

# 2. Worker nodes
resource "ansible_host" "k3s_worker" {
  count = 2
  name = proxmox_vm_qemu.k3s_workers[count.index].name
  groups = ["worker", "kubernetes"]

  variables = {
    ansible_host = split("/", split("ip=", proxmox_vm_qemu.k3s_workers[count.index].ipconfig0)[1])[0]
    ansible_user = "ubuntu"
    node_role = "worker"
    node_blueprint = "kubernetes"
  }
}

# 3. VPN Gateway node
resource "ansible_host" "vpn_node" {
  name = proxmox_vm_qemu.vpn_node.name
  groups = ["vpn"]

  variables = {
    ansible_host = split("/", split("ip=", proxmox_vm_qemu.vpn_node.ipconfig0)[1])[0]
    ansible_user = "ubuntu"
    node_role = "vpn"
    node_blueprint = "gateway"
  }
}