resource "azurerm_kubernetes_cluster" "aks" {
  # checkov:skip=CKV_AZURE_4: Azure Monitor logging skipped for dev environment
  # checkov:skip=CKV_AZURE_115: Private cluster skipped for simplicity
  # checkov:skip=CKV_AZURE_116: Azure policy add-on not required for dev
  # checkov:skip=CKV_AZURE_117: Disk encryption set not configured in dev
  # checkov:skip=CKV_AZURE_170: Using Free tier SLA in dev
  # checkov:skip=CKV_AZURE_226: Ephemeral disk not enabled
  # checkov:skip=CKV_AZURE_227: No specific temp disk encryption setup
  # checkov:skip=CKV_AZURE_168: Pod count default is sufficient
  # checkov:skip=CKV_AZURE_172: Secret rotation handled externally
  # checkov:skip=CKV_AZURE_171: Upgrade channel managed manually
  # checkov:skip=CKV_AZURE_232: No system node separation in this test setup
  # checkov:skip=CKV_AZURE_6
  # checkov:skip=CKV_AZURE_141
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = "Standard_D2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }
}
