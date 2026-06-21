packer {
    required_plugins {
        proxmox = {
            version = ">= 1.1.2"
            source = "github.com/hashicorp/proxmox"
        }
    }
}

variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
}

source "proxmox-iso" "ubuntu" {
    proxmox_url              = var.proxmox_api_url
    username                 = var.proxmox_api_token_id
    token                    = var.proxmox_api_token_secret
    insecure_skip_tls_verify = true

    node                     = "proxmox"
    vm_id                    = 9000
    vm_name                  = "ubuntu-22.04-template"
    template_description     = "First template from Packer"

    iso_file = "local:iso/ubuntu-22.04.5-live-server-amd64.iso"
    # (Option 2) Downlowad ISO
    #iso_url          = "https://releases.ubuntu.com/24.04.4/ubuntu-24.04.4-live-server-amd64.iso"
    #iso_checksum     = "e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433"
    iso_storage_pool = "local"

    cores      = 2
    memory     = 2048
    scsi_controller = "virtio-scsi-pci"

    qemu_agent = true

    disks {
        disk_size       = "20G"
        storage_pool    = "local-zfs"
        type            = "scsi"
    }

    network_adapters {
        bridge = "vmbr0"
        model  = "virtio"
    }

    ssh_username = "ubuntu"
    ssh_password = "SuperTajneHasloDoMojegoPackeraUUU123@"
    ssh_timeout  = "20m"

    ssh_handshake_attempts = "100"

    ssh_shutdown_command = "echo 'SuperTajneHasloDoMojegoPackeraUUU123@' | sudo -S poweroff"
    
    make_template = "true"

    http_directory = "http"

    boot_wait = "5s"
    boot_key_interval = "50ms"
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<enter>",
        "<f10>"
    ]
 
}

build {
    sources = ["source.proxmox-iso.ubuntu"]

    provisioner "shell" {
        inline = [
            "sudo apt-get update",
            "sudo apt-get install -y qemu-guest-agent",
            "sudo systemctl enable qemu-guest-agent"
        ]
    }
}