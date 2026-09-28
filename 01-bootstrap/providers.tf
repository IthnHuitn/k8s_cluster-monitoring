terraform {
  required_version = ">= 1.9.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.229"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.default_zone

  token                    = var.yc_token != "" ? var.yc_token : null
  service_account_key_file = var.yc_sa_key_file != "" ? var.yc_sa_key_file : null
}