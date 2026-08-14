resource "proxmox_vm_qemu" "mgmt-bastion" {
  name   = "mgmt-bastion"
  target_node = "proxmox"
  vmid   = 333

  clone  = "ubuntu-22.04-template"
  full_clone = true

  cores  = 2
  memory = 4096
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
      "echo '=== 0. Disabling interactive prompts & needrestart ==='",
      "sudo sed -i \"s/#\\$nrconf{restart} = 'i';/\\$nrconf{restart} = 'a';/g\" /etc/needrestart/needrestart.conf 2>/dev/null || true",
      "export DEBIAN_FRONTEND=noninteractive",

      "echo '=== 1. Updating system packages ==='",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common git curl unzip python3-pip python3-venv wget gnupg2",
      "echo '=== 2. Setting up ssh keys ==='",
      "if [ ! -f ~/.ssh/id_ed25519 ]; then ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519 -C 'ansible-bastion' -q; fi",

      "echo '=== 2. Installing Ansible ==='",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt install -y ansible",
      "ansible-galaxy collection install cloud.terraform --force",

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

      "echo '=== 6. Setting up GitHub-runner ==='",
      "mkdir actions-runner && cd actions-runner",
      "curl -o actions-runner-linux-x64-2.336.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.336.0/actions-runner-linux-x64-2.336.0.tar.gz",
      "tar xzf ./actions-runner-linux-x64-2.336.0.tar.gz",
      "./config.sh --url https://github.com/kuikml/homelab-platform --token ${var.github_runner_token} --unattended --name mgmt-bastion",
      "sudo ./svc.sh install",
      "sudo ./svc.sh start",

      "echo '=== Environment setup complete. You can now use Ansible, Terraform, Packer, and kubectl on this VM. ==='"
    ]
  }
}