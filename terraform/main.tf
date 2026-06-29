resource "proxmox_vm_qemu" "k3s_nodes" {
  count = 3
  name   = "k3s-node-0${count.index + 1}"
  target_node = "proxmox"
  vmid   = 300 + count.index

  clone  = "ubuntu-22.04-template"
  full_clone = true

  cores  = 2
  memory = 1500
  agent = 1

  boot = "order=scsi0;ide3;net0"
  bootdisk = "scsi0"
  disks {
    scsi {
        scsi0 {
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
    id    = 0
    model = "virtio"
    bridge = "vmbr0"
  }

  os_type = "cloud-init"
  ipconfig0 = "ip=192.168.1.${count.index + 151}/24,gw=192.168.1.1,routes=10.0.0.0/16:192.168.1.160"
  #routes - trasa statyczna do VPC w AWS poprzez tunel VPN StrongSwan (192.168.1.160)
  sshkeys = var.ssh_public_key
}

resource "proxmox_vm_qemu" "vpn_node" {
  name   = "vpn-strongswan"
  target_node = "proxmox"
  vmid   = 311

  clone  = "ubuntu-22.04-template"
  full_clone = true

  cores  = 1
  memory = 512
  agent = 1

  disks {
    scsi {
        scsi0 {
            disk {
                size = "15G"
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
    id    = 0 
    model = "virtio"
    bridge = "vmbr0"
  }

  os_type = "cloud-init"
  ipconfig0 = "ip=192.168.1.160/24,gw=192.168.1.1"
  sshkeys = var.ssh_public_key
}