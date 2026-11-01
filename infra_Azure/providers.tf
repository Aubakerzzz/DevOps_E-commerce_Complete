provider "azurerm" {
  features {}
  # Authentication is handled via environment variables (ARM_CLIENT_ID, etc.)
  # or Azure CLI login inside the container.
}