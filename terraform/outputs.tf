output "platform_nodes" {
  value = merge({
    #Gateway VPN node
    "vpn-gateway" = {
      name = proxmox_vm_qemu.vpn_node.name
      ip        = split("/", split("ip=", proxmox_vm_qemu.vpn_node.ipconfig0)[1])[0]
      role      = "vpn"
      blueprint = "gateway"
  },
    #K3s Master
    "k3s-master" = {
      name = proxmox_vm_qemu.k3s_master.name
      ip        = split("/", split("ip=", proxmox_vm_qemu.k3s_master.ipconfig0)[1])[0]
      role      = "master"
      blueprint = "kubernetes"
  },
    #K3s Workers
    "k3s-worker-01" = {
      for idx, worker in proxmox_vm_qemu.k3s_workers : worker.name => {
        ip       = split("/", split("ip=", worker.ipconfig0)[1])[0]
        role     = "worker"
        blueprint = "kubernetes"
      }
  }
  }
 )
}