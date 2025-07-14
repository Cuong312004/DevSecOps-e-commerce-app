variable "namespace" {
  description = "Namespace to install ArgoCD"
  type        = string
  default     = "argocd"
}

variable "custom_values" {
  description = "YAML values to override default chart config"
  type        = string
  default     = ""
}
