# outputs.tf

output "gke_cluster_name" {
  description = "O nome do cluster GKE Autopilot criado."
  value       = google_container_cluster.autopilot_cluster.name
}

output "gke_cluster_endpoint" {
  description = "O endpoint do cluster GKE."
  value       = google_container_cluster.autopilot_cluster.endpoint
}

output "alloydb_primary_instance_ip" {
  description = "O endereço IP privado da instância primária do AlloyDB."
  value       = google_alloydb_instance.primary_instance.ip_address
  sensitive   = true
}

output "get_ingress_ip_command" {
  description = "Execute este comando após aplicar os manifestos do Kubernetes para obter o IP do Load Balancer."
  value       = "kubectl get ingress birthday-app-ingress -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
}

output "get_kubectl_credentials_command" {
  description = "Comando para configurar o kubectl para se conectar ao novo cluster."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.autopilot_cluster.name} --region ${var.region}"
}
