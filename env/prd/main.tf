module "platform" {
  source = "../../root"

  # General Variables
  environment          = "prd"
  location             = "australiaeast"
  tags                 = {
    env = "prd"
    app = "alz2"
  }

  # VNET Variables
  address_space = ["10.201.0.0/16"]
  address_prefixes_1 = ["10.201.0.0/24"]
  address_prefixes_2 = ["10.201.1.0/24"]
}



