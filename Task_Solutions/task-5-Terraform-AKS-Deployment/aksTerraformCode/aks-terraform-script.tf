locals {
  # Random suffix used across globally-unique names (ACR/KV)
  base_name = lower(var.prefix)
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  number  = true
  special = false
}

# -------------------------
# Resource Group
# -------------------------
resource "azurerm_resource_group" "rg" {
  name     = "${local.base_name}-rg"
  location = var.location
  tags     = var.tags
}

# -------------------------
# Networking: VNet + Subnet (for AKS)
# -------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.base_name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "${local.base_name}-aks-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aks_subnet_prefix]
}

# -------------------------
# Log Analytics (for Container Insights)
# -------------------------
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${local.base_name}-law-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.log_analytics_sku
  retention_in_days   = 30
  tags                = var.tags
}

# -------------------------
# Azure Container Registry (ACR)
# ACR name must be 5-50 alphanumeric and globally unique
# -------------------------
resource "azurerm_container_registry" "acr" {
  name                = "${local.base_name}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.acr_sku
  admin_enabled       = false
  tags                = var.tags
}

# -------------------------
# Key Vault (+ example secret)
# Key Vault name 3-24 chars, alphanumerics and hyphens, globally unique
# -------------------------
resource "azurerm_key_vault" "kv" {
  name                        = "${local.base_name}-kv-${random_string.suffix.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = var.kv_purge_protection_enabled
  enable_rbac_authorization   = false # using access policies for simplicity
  tags                        = var.tags

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "Set", "List", "Delete", "Recover", "Backup", "Restore"
    ]
  }
}

# Example secret (NOTE: KV secret names allow only letters/numbers/hyphen)
resource "azurerm_key_vault_secret" "app_message" {
  name         = "app-message"
  value        = "Hello from Key Vault"
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}

# -------------------------
# AKS (System-assigned identity, Azure CNI)
# -------------------------
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${local.base_name}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${local.base_name}-aks-${random_string.suffix.result}"

  kubernetes_version = null # use current default; set explicitly if you prefer

  default_node_pool {
    name                = "systempool"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    only_critical_addons_enabled = false
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure" # Azure CNI
    load_balancer_sku  = "standard"
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    # docker_bridge_cidr = var.docker_bridge_cidr
    outbound_type      = "loadBalancer"
  }

  # Container Insights (Log Analytics)
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }

  monitor_metrics {
  annotations_allowed = null
  labels_allowed      = null
}

  role_based_access_control_enabled = true

  tags = var.tags

  depends_on = [
    azurerm_subnet.aks,
    azurerm_log_analytics_workspace.law
  ]
}

# -------------------------
# Give AKS permission to pull images from ACR
# Uses Kubelet identity object_id
# -------------------------
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.aks, azurerm_container_registry.acr]
}
