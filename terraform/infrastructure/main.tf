terraform {
  required_version = ">= 0.13"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">=2.8.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://${var.proxmox-host}:8006/api2/json"
  pm_user         = "${var.username}@pam"
  pm_password     = var.password
  pm_tls_insecure = "true"
  pm_parallel     = 10
}


module "k3s" {
  source  = "fvumbaca/k3s/proxmox"
  version = ">= 0.0.0, < 1.0.0" # Get latest 0.X release

  authorized_keys_file = var.pvt_key_file

  proxmox_node = "pve"

  node_template = var.template_vm_name
  proxmox_resource_pool = "project-k3s"

  network_gateway = "192.168.22.1"
  lan_subnet = "192.168.22.0/24"

  support_node_settings = {
    cores = 2
    memory = 4096
    disk_size = "9420M"
  }

  # Disable default traefik and servicelb installs for metallb and traefik 2
  k3s_disable_components = [
    "traefik",
    "servicelb"
  ]

  master_nodes_count = 2
  master_node_settings = {
    cores = 2
    memory = 4096
    disk_size = "19660M"
  }

  # 192.168.22.200 -> 192.168.22.207 (6 available IPs for nodes)
  control_plane_subnet = "192.168.22.200/29"

  node_pools = [
    {
      name = "worker"
      disk_size = "19660M"
      size = 3
      # 192.168.22.208 -> 192.168.22.223 (14 available IPs for nodes)
      subnet = "192.168.22.208/28"
    }
  ]
}

resource "local_file" "config_file" {
    depends_on = [
      module.k3s
    ]
    content  = nonsensitive(module.k3s.k3s_kubeconfig)
    filename = pathexpand("~/.kube/config")
    file_permission = "0644"

}

provider "helm" {
  kubernetes {
   config_path = "~/.kube/config"
  }
}

resource "helm_release" "metallb" {
  depends_on = [
    local_file.config_file
  ]

  name       = "metallb"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metallb"
  namespace  = "metallb-system"
  create_namespace = true

  set {
    name = "configInline"
    value = var.metallb_config
  }

}

resource "helm_release" "argo_cd" {
  depends_on = [
    local_file.config_file
  ]
   
  name       = "argo-cd"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "argo-cd"

  namespace  = "argocd"
  create_namespace = true

  set {
    name  = "server.service.type"
    value = "LoadBalancer"

  }

  set {
    name  = "config.secret.argocdServerAdminPassword"
    value = var.argo_password
  }

}