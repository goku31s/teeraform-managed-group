# Create a custom network
resource "google_compute_network" "my-network" {
  name = "my-network"
}

# Create a subnet within the network
resource "google_compute_subnetwork" "my-subnet" {
  name          = "my-subnet"
  network       = google_compute_network.my-network.self_link
  ip_cidr_range = "10.0.1.0/24"  # Replace with your desired subnet CIDR range
  region        = "us-central1"  # Replace with your desired region
}

# Create firewall rules
resource "google_compute_firewall" "allow-http-https" {
  name    = "allow-http-https"
  network = google_compute_network.my-network.self_link

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh-tf"
  network = google_compute_network.my-network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-internal" {
  name    = "allow-internal-tf"
  network = google_compute_network.my-network.self_link

  allow {
    protocol = "all"
  }

  source_tags = ["my-instance-group"]
}

resource "google_compute_firewall" "allow-iap" {
  name    = "allow-iap"
  network = google_compute_network.my-network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}
