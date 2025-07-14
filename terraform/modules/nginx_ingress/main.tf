resource "helm_release" "nginx_ingress" {
  name       = var.name
  namespace  = var.namespace
  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.chart_version

  values = [<<EOF
    controller:
      service:
        type: LoadBalancer
    EOF
  ]
}
