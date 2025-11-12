output "kubeconfig" {
  value     = kind_cluster.default.kubeconfig
  sensitive = true
}

output "cluster_name" {
  value = kind_cluster.default.name
}

output "endpoint" {
  value = kind_cluster.default.endpoint
}
