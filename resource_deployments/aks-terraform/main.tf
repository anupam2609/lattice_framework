terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# resource group
data "azurerm_resource_group" "existing_rg" {
  name = var.resource_group_name
}

# aks cluster -- kept to minimal cost to reduce the charges
resource "azurerm_kubernetes_cluster" "aks" {
  name      = var.cluster_name
  location  = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  dns_prefix = "${var.cluster_name}-dns"

  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name                = "systempool"
    node_count          = 1
    vm_size             = var.node_vm_size
    type                = "VirtualMachineScaleSets"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"
  }
}

resource "local_file" "kube_config" {
  content = azurerm_kubernetes_cluster.aks.kube_config_raw
  filename = "${path.module}/kubeconfig"
}