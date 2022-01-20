output "kubeconfig" {
  value = module.k3s.k3s_kubeconfig
  sensitive = true
}