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
  ipconfig0 = "ip=192.168.1.${count.index + 151}/24,gw=192.168.1.1"
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

resource "proxmox_vm_qemu" "mgmt-bastion" {
  name   = "mgmt-bastion"
  target_node = "proxmox"
  vmid   = 333

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
  ipconfig0 = "ip=192.168.1.166/24,gw=192.168.1.1"
  sshkeys = var.ssh_public_key

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_ed25519")
    host        = "192.168.1.166"
}

  provisioner "remote-exec" {
    inline = [
      "echo '=== 1. Updating system packages ==='",
      "sudo apt update",
      "sudo apt-get install -y software-properties-common git curl unzip python3-pip python3-venv wget gnupg2", 

      "echo '=== 2. Installing Ansible ==='",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt install -y ansible",

      "echo '=== 3. Installing Terraform and Packer ==='",
      "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list",
      "sudo apt update",
      "sudo apt install -y terraform packer",

      "echo '=== 4. Installing kubectl ==='",
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg",
      "sudo mkdir -p -m 755 /etc/apt/keyrings",
      "sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt update",
      "sudo apt install -y kubectl",

      "echo '=== 5. Cloning Repositories from GitHub ==='",
      "cd ~",
      "git clone https://github.com/kuikml/homelab-platform.git",

      "echo '=== Environment setup complete. You can now use Ansible, Terraform, Packer, and kubectl on this VM. ==='"
    ]
  }
}