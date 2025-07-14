provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "resource_group" {
  source   = "../../modules/resource_group"
  name     = var.resource_group_name
  location = var.location
}

module "network" {
  source              = "../../modules/network"
  vnet_name           = "staging-vnet"
  address_space       = "10.0.0.0/16"
  subnet_name         = "staging-subnet"
  subnet_prefix       = "10.0.1.0/24"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
}

module "acr" {
  source              = "../../modules/acr"
  name                = "stagingacr1234"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
}

module "aks" {
  source              = "../../modules/aks"
  name                = "staging-aks"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  dns_prefix          = "staging-aks"
  node_count          = 1
}

resource "null_resource" "get_kubeconfig" {
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${module.resource_group.name} --name ${module.aks.name} --overwrite-existing"
  }

  depends_on = [module.aks]
}


module "jenkins" {
  source              = "../../modules/jenkins"
  name                = "jenkins-staging-vm"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.network.subnet_id
  public_key_path     = var.public_key_path 
}


provider "kubernetes" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = module.aks.kube_config.host
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  }
}


module "argocd" {
  source    = "../../modules/argocd"
  namespace = "argocd"
}