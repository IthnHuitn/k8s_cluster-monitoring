output "service_account_id" {
  value = yandex_iam_service_account.terraform_sa.id
}

output "service_account_name" {
  value = yandex_iam_service_account.terraform_sa.name
}

output "k8s_sa_id" {
  value = yandex_iam_service_account.k8s_sa.id
}

output "registry_id" {
  value = yandex_container_registry.main.id
}

output "registry_url" {
  value = "cr.yandex/${yandex_container_registry.main.id}"
}

output "access_key" {
  value     = yandex_iam_service_account_static_access_key.terraform_sa_key.access_key
  sensitive = true
}

output "secret_key" {
  value     = yandex_iam_service_account_static_access_key.terraform_sa_key.secret_key
  sensitive = true
}

output "sa_key_file_content" {
  value     = yandex_iam_service_account_key.terraform_sa_authorized_key.private_key
  sensitive = true
}

output "bucket_name" {
  value = yandex_storage_bucket.terraform_state.bucket
}

output "bucket_domain_name" {
  value = yandex_storage_bucket.terraform_state.bucket_domain_name
}

output "s3_endpoint" {
  value = "storage.yandexcloud.net"
}

output "backend_config" {
  value = {
    endpoint = "storage.yandexcloud.net"
    bucket   = yandex_storage_bucket.terraform_state.bucket
    region   = "ru-central1"
  }
}

output "kms_key_id" {
  value = yandex_kms_symmetric_key.state_bucket_key.id
}
