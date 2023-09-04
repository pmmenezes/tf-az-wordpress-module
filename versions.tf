terraform {
  required_version = "~> 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.0"
    }
      random = {
      source = "hashicorp/random"
      version = "~> 3.5.1"
    }

  }
}