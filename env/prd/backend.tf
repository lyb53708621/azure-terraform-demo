terraform {
  backend "azurerm" {
    use_azuread_auth     = true
    use_cli              = true
    resource_group_name  = "terraform-test"
    storage_account_name = "terraformsto1"
    container_name       = "tfstatefilecontainer"
    key                  = "prd.github.terrasform.tfstate"
  }
}