provider "google" {
  credentials = file("~/.gcp/bright-link-281011-933bbf38e6bb.json")
  project     = "bright-link-281011"
  region      = "europe-west1"
}
