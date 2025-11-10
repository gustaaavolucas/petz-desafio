module "k8s_base" {
  source    = "./modules/k8s-base"
  namespace = "apps"
}

module "argocd" {
  source       = "./modules/argocd"
  namespace    = "argocd"
  service_type = "NodePort"
}
