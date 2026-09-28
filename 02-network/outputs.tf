output "network_id" {
  description = "VPC network ID"
  value       = yandex_vpc_network.main.id
}

output "subnet_ids" {
  description = "Map of subnet IDs by zone"
  value       = { for k, s in yandex_vpc_subnet.main : s.zone => s.id }
}

output "security_group_id" {
  description = "Security group ID"
  value       = yandex_vpc_security_group.k8s.id
}
