resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "prometheus" {
  name       = var.name
  namespace  = var.namespace
  chart      = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = var.chart_version
  timeout    = 600
  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [kubernetes_namespace.this]
}
