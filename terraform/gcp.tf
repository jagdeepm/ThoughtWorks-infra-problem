provider "google" {
  credentials = file("newsfeed-terraform-sa-key.json")
  project     = "thoughtworks-newsfeedapp"
  region      = "europe-west4"
  zone        = "europe-west4-a"
}


# IP Address
resource "google_compute_address" "ip_address" {
  name = "newsfeed-ip-${terraform.workspace}"
}

# Network
data "google_compute_network" "default" {
  name = "default"
}

# Firewall Rule

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-${terraform.workspace}"
  #network = google_compute_network.default.name
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["8000", "5656", "6000", "6500"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["allow-http-${terraform.workspace}"]
}

# OS Image
data "google_compute_image" "cos_image" {
  family  = "cos-97-lts"
  project = "cos-cloud"
}

# Compute Engine Instance
resource "google_compute_instance" "instance" {
  name         = "${var.app_name}-vm-${terraform.workspace}"
  machine_type = var.gcp_machine_type
  zone         = "europe-west4-a"

  tags = google_compute_firewall.allow_http.target_tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos_image.self_link
    }
  }

  network_interface {
    network = data.google_compute_network.default.name

    access_config {
      nat_ip = google_compute_address.ip_address.address
    }
  }

  service_account {
    scopes = ["storage-ro"]
  }
}