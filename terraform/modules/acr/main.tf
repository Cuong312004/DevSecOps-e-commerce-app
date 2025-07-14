resource "azurerm_container_registry" "acr" {
  # checkov:skip=CKV_AZURE_163: Vulnerability scanning requires Microsoft Defender (paid)
  # checkov:skip=CKV_AZURE_164: Signed image enforcement not fully supported in Terraform
  # checkov:skip=CKV_AZURE_165: Geo-replication skipped for single region use
  # checkov:skip=CKV_AZURE_166: Quarantine feature not supported in Terraform
  # checkov:skip=CKV_AZURE_167: Retention policy requires az CLI or REST API
  # checkov:skip=CKV_AZURE_233: Zone redundancy requires Premium SKU
  # checkov:skip=CKV_AZURE_237: Dedicated data endpoints unsupported in basic tier
  # checkov:skip=CKV_AZURE_139
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
}
