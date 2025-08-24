variable "prefix" {
  description = "Short name prefix for resources (letters/numbers, start with letter). Example: 'snu'"
  type        = string
  default     = "snu"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "node_count" {
  description = "AKS default node pool count"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "AKS node VM size"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = string
  default     = "10.10.0.0/16"
}

variable "aks_subnet_prefix" {
  description = "CIDR for AKS subnet"
  type        = string
  default     = "10.10.1.0/24"
}

variable "service_cidr" {
  description = "Kubernetes service CIDR (non-overlapping)"
  type        = string
  default     = "10.240.0.0/16"
}

variable "dns_service_ip" {
  description = "Kubernetes DNS service IP (inside service_cidr)"
  type        = string
  default     = "10.240.0.10"
}

variable "docker_bridge_cidr" {
  description = "Docker bridge CIDR"
  type        = string
  default     = "172.17.0.1/16"
}

variable "log_analytics_sku" {
  description = "Log Analytics SKU"
  type        = string
  default     = "PerGB2018"
}

variable "acr_sku" {
  description = "ACR SKU: Basic, Standard, Premium"
  type        = string
  default     = "Standard"
}

variable "kv_purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = { project = "simple-node-ui", env = "dev" }
}
