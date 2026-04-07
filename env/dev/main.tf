module "platform" {
  source = "../../root"

  # General Variables xxx
  environment          = "dev"
  location             = "australiaeast"
  tags                 = {
    env = "dev"
    app = "alz2"
  }

  # VNET Variables
  address_space = ["10.200.0.0/16"]
  address_prefixes_1 = ["10.200.0.0/24"]
  address_prefixes_2 = ["10.200.1.0/24"]
}



