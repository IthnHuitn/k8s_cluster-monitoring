# ==================== Cloud Credentials ====================
variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "service_account_key_file" {
  description = "Path to authorized key file for creating bucket"
  type        = string
  default     = "/tmp/.authorized_key_diplom.json"
}

variable "default_zone" {
  description = "Default availability zone"
  type        = string
  default     = "ru-central1-a"
}

# ==================== VPC Configuration ====================
variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "diplom-vpc"
}

variable "subnets" {
  description = "Subnets configuration"
  type = list(object({
    name           = string
    zone           = string
    v4_cidr_blocks = list(string)
  }))
  default = [
    {
      name           = "subnet-a"
      zone           = "ru-central1-a"
      v4_cidr_blocks = ["10.10.1.0/24"]
    },
    {
      name           = "subnet-b"
      zone           = "ru-central1-b"
      v4_cidr_blocks = ["10.10.2.0/24"]
    },
    {
      name           = "subnet-d"
      zone           = "ru-central1-d"
      v4_cidr_blocks = ["10.10.3.0/24"]
    }
  ]
}