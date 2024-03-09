terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.94.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "953c0ff7-b528-47d0-8ee7-ff9262368d59"
  features {}
}