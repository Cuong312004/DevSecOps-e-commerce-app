resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.46.8"
  namespace        = var.namespace
  create_namespace = true

  values = var.custom_values != "" ? [var.custom_values] : []
}
