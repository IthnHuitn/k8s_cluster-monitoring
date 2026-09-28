output "master_public_ip" {
  description = "Master node public IP"
  value       = yandex_compute_instance.master.network_interface[0].nat_ip_address
}

output "master_internal_ip" {
  description = "Master node internal IP"
  value       = yandex_compute_instance.master.network_interface[0].ip_address
}

output "load_balancer_public_ip" {
  description = "Load balancer public IP"
  value = flatten([
    for l in yandex_lb_network_load_balancer.k8s_lb.listener :
    [for s in l.external_address_spec : s.address]
  ])[0]
}

output "worker_internal_ips" {
  description = "Worker nodes internal IPs"
  value       = [for w in yandex_compute_instance.worker : w.network_interface[0].ip_address]
}

output "state_bucket" {
  description = "S3 bucket used for state"
  value       = var.state_bucket_name
}

locals {
  lb_ip = flatten([
    for l in yandex_lb_network_load_balancer.k8s_lb.listener :
    [for s in l.external_address_spec : s.address]
  ])[0]
}

output "app_url" {
  description = "Application URL via Load Balancer"
  value       = "http://app.${local.lb_ip}.nip.io"
}

output "grafana_url" {
  description = "Grafana URL via Load Balancer"
  value       = "http://${local.lb_ip}/"
}
