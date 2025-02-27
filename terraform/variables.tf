variable "ssh_public_key" {
  description = "Публичный SSH ключ для доступа к ВМ"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
