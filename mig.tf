resource "google_compute_instance_template" "my-instance-template" {
  name        = "my-instance-template"
  machine_type = var.instance_type
  region      = var.region

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
    auto_delete  = true
  }

  network_interface {
    network = google_compute_network.my-network.self_link
    subnetwork = google_compute_subnetwork.my-subnet.self_link
  
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    echo "Hostname is $(hostname)" > /var/www/html/index.html
    systemctl restart apache2
    systemctl enable ssh
    systemctl restart ssh
  SCRIPT
}

resource "google_compute_instance_group_manager" "my-instance-group" {
  name               = "my-instance-group-tf"
  base_instance_name = "my-instance"
  target_size        = 1  # Initial size of the MIG
  zone               = var.zone

  version {
    instance_template = google_compute_instance_template.my-instance-template.self_link
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check = google_compute_http_health_check.my-health-check.id
    initial_delay_sec = 300  # Adjust as per your requirements
  }

  update_policy {
    type           = "PROACTIVE"
    minimal_action = "RESTART"
    max_surge_fixed = 1
    max_unavailable_fixed = 1  # Set to a value greater than 0
  }

  depends_on = [
    google_compute_instance_template.my-instance-template,
  ]
}

resource "google_compute_autoscaler" "my-autoscaler" {
  name   = "my-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.my-instance-group.id

  autoscaling_policy {
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.01
    }
  }
}

resource "google_compute_router" "my-router" {
  name    = "my-router-tf"
  network = google_compute_network.my-network.self_link
  region  = var.region
}

resource "google_compute_router_nat" "my-router-nat" {
  name                               = "my-router-nat"
  router                             = google_compute_router.my-router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_http_health_check" "my-health-check" {
  name               = "my-health-check"
  request_path       = "/"
  check_interval_sec = 5
  timeout_sec        = 5
}

resource "google_compute_backend_service" "my-backend-service" {
  name                 = "my-backend-service"
  backend {
    group            = google_compute_instance_group_manager.my-instance-group.instance_group
    balancing_mode   = "UTILIZATION"
    max_utilization  = 0.8
  }
  health_checks        = [google_compute_http_health_check.my-health-check.id]
  protocol             = "HTTP"
  timeout_sec          = 10
}

resource "google_compute_url_map" "my-url-map" {
  name            = "my-url-map"
  default_service = google_compute_backend_service.my-backend-service.id
}

resource "google_compute_target_http_proxy" "my-http-proxy" {
  name    = "my-http-proxy"
  url_map = google_compute_url_map.my-url-map.id
}

resource "google_compute_global_forwarding_rule" "my-forwarding-rule" {
  name       = "my-forwarding-rule"
  target     = google_compute_target_http_proxy.my-http-proxy.id
  port_range = "80"
}

output "load_balancer_ip" {
  value = google_compute_global_forwarding_rule.my-forwarding-rule.ip_address
}