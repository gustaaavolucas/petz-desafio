resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = var.namespace

  values = [
    <<-YAML
    server:
      replicas: 1
      extraArgs:
        - --insecure
      service:
        type: ClusterIP
    YAML
  ]
}
