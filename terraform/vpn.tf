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


##################################################
# Configure VPS's network
##################################################
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
    ports     = ["51820"]
  }
  allow {
    protocol  = "tcp"
    ports     = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = var.vm_tags
}

##################################################
# Print output
##################################################
output "public_ip" {
  value = google_compute_address.static.address
}


##################################################
# Create VPS
##################################################
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
  # provisioner "local-exec" {
  #   # command = "echo ${self.network_interface.0.access_config.0.nat_ip}"
  #   command = "echo ${data.template_file.docker_script.rendered}"
  #   # when = create
  # }
  connection {
    type = "ssh"
    user = "${split("@", jsondecode(file(var.gcloud_credentials)).client_email)[0]}"
    private_key = "${file(var.vm_manager_user_private_key_file)}"
    host = self.network_interface.0.access_config.0.nat_ip
  }


##################################################
# Create folders temporary in home directory of instance
##################################################
  provisioner "remote-exec" {
    inline = [
    "mkdir -p  ~/wireguard/docker/webui",
    "mkdir -p  ~/wireguard/docker/wireguard",
    "mkdir -p  ~/wireguard/nginx",
    "mkdir -p  ~/wireguard/webui",
    "mkdir -p  ~/wireguard/wireguard_configs"
    ]
  }


##################################################
# Copy wireguard files separetely
##################################################
  provisioner "file" {
    content     = templatefile("../docker/wireguard/.env.tpl",
      {
        nginx_host = var.wg_url,
        wg_client_amount = var.wg_client_amount
      })
    destination = "wireguard/docker/wireguard/.env"
  }
  provisioner "file" {
    source      = "../docker/wireguard/.env.sample"
    destination = "wireguard/docker/wireguard/.env.sample"
  }
  provisioner "file" {
    source      = "../docker/wireguard/docker-compose.yml"
    destination = "wireguard/docker/wireguard/docker-compose.yml"
  }


##################################################
# Copy wireguard WebUI files
##################################################
  provisioner "file" {
    source      = "../docker/webui/"
    destination = "wireguard/docker/webui"
  }
  provisioner "file" {
    content     = templatefile("../docker/webui/.env.tpl",
      {
        nginx_host = var.wg_url,
        email = var.letsenrypt_email
      })
    destination = "wireguard/docker/webui/.env"
  }
  provisioner "file" {
    source      = "../webui/"
    destination = "wireguard/webui"
  }
  provisioner "file" {
    source      = "../nginx/"
    destination = "wireguard/nginx"
  }


##################################################
# Install software, Wireguard and Wireguard WebUI
##################################################
  provisioner "remote-exec" {
    script = "../scripts/basic.sh"
  }
  provisioner "remote-exec" {
    inline = ["${templatefile("../scripts/docker.sh.tpl", {user = local.service_user})}"]
  }
  provisioner "remote-exec" {
    script = "../scripts/wireguard.sh"
  }
  provisioner "remote-exec" {
    inline = ["${templatefile("../scripts/wireguard_webui.sh.tpl",
      {
        nginx_host = var.wg_url,
        email = var.letsenrypt_email
      })}"]
  }
}


##################################################
# Print output
##################################################
output "out_ip" {
  value = google_compute_address.static.address
}
