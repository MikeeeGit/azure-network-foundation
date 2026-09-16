# Supply new backend coordinates with the shared helpers or -backend-config.
# Never reuse the original estate's backend for these public examples.
terraform {
  backend "azurerm" {}
}
