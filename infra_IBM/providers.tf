provider "ibm" {
  region = var.region
  # Authentication via IC_API_KEY environment variable
  # or ibmcloud_api_key argument.
}