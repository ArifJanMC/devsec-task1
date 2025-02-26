resource "virtualbox_vm" "linux_hardening_vm" {
  name      = "linux-hardening-vm"
  image     = "https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2"
  cpus      = 2
  memory    = "2048 mib"

  network_adapter {
    type           = "nat"
    device         = "IntelPro1000MTServer"
    host_interface = "vboxnet0"
  }

  # Конфигурация для SSH доступа
  provisioner "file" {
    source      = "~/.ssh/id_rsa.pub"
    destination = "/home/debian/authorized_keys"
  }
}
