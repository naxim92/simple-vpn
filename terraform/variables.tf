variable "gcloud_credentials" {
  type = string
  default = "../private/account.json"
}

variable "gcloud_project" {
  type = string
}

variable "gcloud_region" {
  type = string
  default = "us-central1"
}

variable "vm_machine_type" {
  type = string
  default = "f1-micro"
}

variable "vm_manager_user" {
  type = string
  default = "manager"
}

variable "vm_manager_user_pub_key_file" {
  type = string
  default = "../private/manager_key.pub"
}

variable "vm_manager_user_private_key_file" {
  type = string
  default = "../private/manager_key.private"
}

variable "vm_tags" {
  type = list(string)
}

variable "vm_name" {
  type = string
}

variable "vm_image" {
  type = string
}

variable "network_public_ip_name" {
  type = string
  default = "vm-public-address"
}

variable "wg_url" {
  type = string
  default = "wireguard.local"
}

variable "letsenrypt_email" {
  type = string
  default = "letencrypt@email.com"
}

variable "wg_client_amount" {
  type = number
  default = 10
}
