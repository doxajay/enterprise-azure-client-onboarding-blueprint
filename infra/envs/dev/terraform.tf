terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  cloud {
    organization = "YOUR_TFC_ORG_NAME"
    workspaces {
      name = "onboarding-dev"
    }
  }
}
