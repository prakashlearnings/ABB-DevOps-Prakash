# Adjust as needed
prefix              = "abb"
location            = "eastus"
node_count          = 2
node_vm_size        = "Standard_DS2_v2"
vnet_address_space  = "10.10.0.0/16"
aks_subnet_prefix   = "10.10.1.0/24"
service_cidr        = "10.240.0.0/16"
dns_service_ip      = "10.240.0.10"
docker_bridge_cidr  = "172.17.0.1/16"
acr_sku             = "Standard"
kv_purge_protection_enabled = true
tags = {
  project = "simple-node-ui"
  env     = "dev"
}
