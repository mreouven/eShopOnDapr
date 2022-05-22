data "azurerm_kubernetes_service_versions" "current" {
  location = "East US"
}

//using locals because interpolation would work
locals {
  common_tags = {
    environment = "demo"
    creation_date = formatdate("YYYY-MM-DD", timestamp())
  }
}

module "kube-group" {
  source = "../../modules/azure/resource_group"
  rg_name = "${var.prefix}-cluster-rg"
  rg_location = var.location
  rg_tags     = local.common_tags
}

module "acr" {
  source = "../../modules/azure/acr"
  tags   = local.common_tags
  resource_group_name = module.kube-group.name
  location = var.location
  acr_name = var.acr_name
}

module "vault" {
  source = "../../modules/azure/keyvault"
  location = var.location
  tags = local.common_tags
  prefix = var.prefix
  resource_group_name = module.kube-group.name
}

module "loganalytics" {
  source = "../../modules/azure/loganalytics"
  resource_group_name = module.kube-group.name
  tags = local.common_tags
  prefix = var.prefix
  location = var.location
}

module "vnet" {
  source = "../../modules/azure/vnet"
  tags                = local.common_tags
  vnet_address_space  = var.vnet_address_space
  vnet_location       = module.kube-group.rg_location
  vnet_resource_group = module.kube-group.name
  subnets             = var.subnets
  prefix              = var.prefix
}


module "mssql_server" {
  source = "../../modules/azure/mssql_server"
  location            = var.location
  vnet_rule_subnet_id = module.vnet.subnet_ids["kube-subnet"]
  databases = var.databases
  sql_firewall_rules = var.sql_firewall_rules
  tags = local.common_tags
  prefix = var.prefix
  resource_group_name = module.kube-group.name
}

module "service_bus" {
  source = "../../modules/azure/servicebus"
  resource_group_name = module.kube-group.name
  tags                = local.common_tags
  location = var.location
  prefix = var.prefix
}

module "cosmosdb" {
  source = "../../modules/azure/cosmosdb"
  location = var.location
  resource_group_name = module.kube-group.name
  tags = local.common_tags
  prefix = var.prefix
}


module "kube" {
  source                          = "../../modules/azure/aks"
  depends_on                      = [
    module.vnet.subnet_ids
  ]
  prefix                          = var.prefix
  kube_resource_group_name        = module.kube-group.name
  dns_prefix                      = var.prefix
  location                        = var.location
  private_cluster_enabled         = false
  tags = local.common_tags
  loganalytics_workspace_id = module.loganalytics.log_analytics_workspace_id
  default_node_pool_name = "systempool"
  vnet_subnet_id = module.vnet.subnet_ids["kube-subnet"]
  api_server_authorized_ip_ranges  = var.api_server_authorized_ip_ranges
  default_node_pool_vnet_subnet_id = module.vnet.subnet_ids["kube-subnet"]
  node_resource_group              = "${var.prefix}-nodes-rg"
  admin_group_object_ids = var.admin_group_object_ids
  tenant_id = var.tenant_id
  local_account_disabled = false
  http_application_routing_enabled = false
  azurerm_container_registry_id = module.acr.acr_id
  azurerm_container_registry_enabled = true
}

module "kube_nodepools" {
  source = "../../modules/azure/aks_nodepools"
  additional_nodepools = var.additional_nodepools
  kubernetes_cluster_id = module.kube.kube_cluster_id
  vnet_subnet_id        = module.vnet.subnet_ids["kube-subnet"]
  orchestrator_version = data.azurerm_kubernetes_service_versions.current.latest_version
}

module "key_vault_identity" {
  source = "../../modules/azure/user_assigned_identity"
  location = module.kube.kube_cluster_location
  identity_name = "key-vault-identity"
  identity_resourcegroup_name = module.kube.kube_cluster_node_group
}

module "aad_pod_identity" {
  source = "../../modules/azure/user_assigned_identity"
  location = module.kube.kube_cluster_location
  identity_name = "pod-identity"
  identity_resourcegroup_name = module.kube.kube_cluster_node_group
}

