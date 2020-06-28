resource "google_project_service" "kubernetes" {
  service = "container.googleapis.com"
}

resource "google_container_cluster" "kubernetes" {
  name               = "otus-k8s-cluster"
  location           = "europe-west1"
  min_master_version = "1.16.9-gke.6"
  monitoring_service = "none"
  logging_service    = "none"

  node_locations = [
    "europe-west1-d",
  ]

  remove_default_node_pool = true
  initial_node_count       = 2

  master_auth {
    username = ""
    password = ""
  }


}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name               = "otus-nodes"
  location           = google_container_cluster.kubernetes.location
  cluster            = google_container_cluster.kubernetes.name
  initial_node_count = 1
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    preemptible  = true
    machine_type = "n1-standard-2"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/monitoring.write"
    ]
  }
}
