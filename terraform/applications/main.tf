terraform {
  required_version = ">= 0.13"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.7.1"
    }
  }
}

provider "helm" {
  kubernetes {
   config_path = "~/.kube/config"
  }
}

resource "helm_release" "nginx_ingress" {

  name       = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  namespace = "ingress-nginx"
  create_namespace = true

}

provider "kubernetes" {
   config_path    = "~/.kube/config"
}

resource "kubernetes_manifest" "argocd_app" {

  manifest = {
    apiVersion  = "argoproj.io/v1alpha1"
    kind        = "Application"
    metadata    = {
      name       = "easy-claim"
      namespace  = "argocd"
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
        project     = "default"
        destination = {
            name       = ""
            namespace  = "easyclaim"
            server     = "https://kubernetes.default.svc"
        }
        source = {
            path       = "kustomize/base"
            repoURL    = "https://github.com/ivan-krushkov/telerik-final-project.git"
            targetRevision = "HEAD"
            directory = {
              recurse = true
            }
        }
        syncPolicy = {
            automated = {
                prune    = true
                selfHeal = true
            }
            syncOptions = ["CreateNamespace=true"]
        }
    }
  }
}
