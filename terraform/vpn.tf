terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
    template = {
      source = "hashicorp/template"
    }
  }
}

locals {
  service_user  = "${split("@", jsondecode(file(var.gcloud_credentials)).client_email)[0]}"
}

provider "google" {
  credentials = "${file(var.gcloud_credentials)}"
  project     = var.gcloud_project
  region      = var.gcloud_region
}

resource "google_compute_instance" "vpn" {
  name         = var.vm_name
  hostname     = "${var.vm_name}.local"
  machine_type = var.vm_machine_type
  zone         = "${var.gcloud_region}-a"
  tags         = var.vm_tags
  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }

  metadata = {
      ssh-keys = "${split("@", jsondecode(file(var.gcloud_credentials)).client_email)[0]}:${file(var.vm_manager_user_pub_key_file)} ${jsondecode(file(var.gcloud_credentials)).client_email}"
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  provisioner "local-exec" {
    # command = "echo ${self.network_interface.0.access_config.0.nat_ip}"
    command = "echo ${data.template_file.docker_script.rendered}"
    # when = create
  }

  connection {
    type     = "ssh"
    user     = "${split("@", jsondecode(file(var.gcloud_credentials)).client_email)[0]}"
    private_key="${file(var.vm_manager_user_private_key_file)}"
    host     = self.network_interface.0.access_config.0.nat_ip
  }

  provisioner "remote-exec" {
    inline = [
    "mkdir  ~/wireguard"
    ]
  }

  provisioner "file" {
    source      = "../wireguard/.env"
    destination = "wireguard/.env"
  }

  provisioner "file" {
    source      = "../wireguard/docker-compose.yml"
    destination = "wireguard/docker-compose.yml"
  }

  provisioner "remote-exec" {
    script = "../scripts/basic.sh"
  }

  provisioner "remote-exec" {
    inline = [ data.template_file.docker_script.rendered ]
  # inline = "${templatefile("../scripts/docker.sh.tpl", {user = local.service_user})}"
  }

  provisioner "remote-exec" {
    script = "../scripts/wireguard.sh"
  }
}

resource "google_compute_address" "static" {
  name = var.network_public_ip_name
  project = var.gcloud_project
  region = var.gcloud_region
}

resource "google_compute_firewall" "vpn_rules" {
  project     = var.gcloud_project
  name        = "${var.vm_name}-allow-wireguard"
  network     = "default"
  description = "Creates firewall rule for working wireguard"

  allow {
    protocol  = "udp"
    ports     = ["443", "51820"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = var.vm_tags
}

data "template_file" "docker_script" {
  template = file("../scripts/docker.sh.tpl")
  vars = {
    user = local.service_user
  }
}

output "public_ip" {
  value = google_compute_address.static.address
}

output "metadata" {
  value = google_compute_instance.vpn.metadata
}