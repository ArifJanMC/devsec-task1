variable "ssh_public_key" {
  description = "Публичный SSH ключ для доступа к ВМ"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

output "vm_ip" {
  value = virtualbox_vm.linux_hardening_vm.network_adapter[0].ipv4_address
}