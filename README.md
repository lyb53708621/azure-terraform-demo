# azure-terraform-demo
Use this Repo to demonstrate IaC with Terraform

# Trigger Azure policy scan
az policy state trigger-scan 
az policy state trigger-scan --resource-group <rg-name>
az policy state trigger-scan --subscription <subscription-id>