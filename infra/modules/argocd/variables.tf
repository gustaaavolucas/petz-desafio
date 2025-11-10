variable "namespace" {
  type    = string
  default = "argocd"
}

variable "service_type" {
  type    = string
  default = "NodePort"
}
