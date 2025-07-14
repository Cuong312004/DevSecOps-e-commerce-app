/*
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstateaccount123"
    container_name       = "tfstate"
    key                  = "staging.terraform.tfstate"
  }
}
*/
