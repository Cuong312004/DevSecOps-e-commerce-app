resource "helm_release" "sonarqube" {
  name       = var.name
  repository = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart      = "sonarqube"
  namespace  = var.namespace
  version    = var.chart_version

  create_namespace = true

  values = [
    file("${path.module}/values.yaml")
  ]
}
