resource "virtualbox_vm" "linux_hardening_vm" {
  name      = "linux-hardening-vm"
  image     = "https://app.vagrantup.com/debian/boxes/bullseye64/versions/11.20230615.1/providers/virtualbox.box"
  cpus      = 2
  memory    = "2048 mib"
  
  # If you need to pass cloud-init or other initialization data
  # Create a file in the same directory first
  # user_data = file("${path.module}/user_data")
  
  network_adapter {
    type           = "nat"
    host_interface = "vboxnet0"  # Make sure this interface exists
  }
}

output "vm_ip" {
  value = virtualbox_vm.linux_hardening_vm.network_adapter[0].ipv4_address
}