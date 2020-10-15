resource "google_project_service" "kubernetes" {
  service = "container.googleapis.com"
}

resource "google_container_cluster" "kubernetes" {
  name               = "otus-k8s-cluster"
  location           = "europe-west1"
  min_master_version = "1.16.15-gke.500"
  monitoring_service = "none"
  # stackdriver disabled
  logging_service = "none"

  node_locations = [
    "europe-west1-d",
  ]

  remove_default_node_pool = true
  initial_node_count       = 3

  master_auth {
    username = ""
    password = ""
  }


}

resource "google_container_node_pool" "default-pool" {
  name               = "default-pool"
  location           = google_container_cluster.kubernetes.location
  cluster            = google_container_cluster.kubernetes.name
  initial_node_count = 3
  autoscaling {
    min_node_count = 3
    max_node_count = 5
  }

  node_config {
    preemptible  = true
    machine_type = "e2-medium"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/monitoring.write"
    ]
  }
}


resource "google_compute_address" "ip_address" {
  name         = "gke-ext"
  region       = "europe-west1"
  network_tier = "STANDARD"
}
