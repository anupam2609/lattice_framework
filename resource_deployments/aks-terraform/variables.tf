variable "resource_group_name" {
  description = "Use existing RG"
  default = "dataMigrate-v1"
}

variable "cluster_name" {
  description = "AKS cluster name"
  default = "aks-xpander-dev"
}

variable "location" {
  description = "Region (not used since RG already fixed)"
  default = "southindia"
}

variable "node_vm_size" {
  description = "Cheapest recommended VM"
  default = "Standard_B2s"
}

variable "kubernetes_version" {
  description = "AKS version"
  default = "1.33"
}