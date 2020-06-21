provider "google" {
  credentials = file("~/.gcp/My_Project-42ebef5ee766.json")
  project     = "alert-imprint-279710"
  region      = "europe-west1"
}
