# Kubernetes Cluster Infrastructure (Terraform)

Terraform-модули для развёртывания инфраструктуры Kubernetes-кластера в Yandex Cloud: service accounts, сеть, виртуальные машины, load balancer и генерация inventory для Ansible.

## Структура

```
.
├── 01-bootstrap/              # Service accounts, S3 backend, базовая подготовка
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── personal.auto.tfvars          # (в .gitignore) значения для YC
│   └── personal.auto.tfvars.example  # пример заполнения
├── 02-network/                # VPC, подсети, security groups, маршруты
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── personal.auto.tfvars
│   └── personal.auto.tfvars.example
├── 03-infrastructure/         # Виртуальные машины, LB, генерация inventory
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── templates/
│   │   └── inventory.tpl      # Шаблон Ansible-инвентаря
│   ├── personal.auto.tfvars
│   └── personal.auto.tfvars.example
└── README.md
```

## Модули

| Модуль | Назначение |
|---|---|
| `01-bootstrap` | Создание service accounts (`ci-cd-sa`, `diplom-terraform-sa`, `diplom-k8s-sa`), настройка S3-бэкенда для state, назначение ролей |
| `02-network` | VPC, три подсети в разных зонах доступности, security groups (Kubernetes API, SSH, ingress-порты), таблица маршрутизации |
| `03-infrastructure` | Виртуальные машины (1 master + 3 workers), Network Load Balancer для ingress, генерация `hosts.yml` для Ansible через `inventory.tpl` |

## Порядок запуска

Модули выполняются строго по очереди — каждый использует outputs предыдущего.

```bash
# 1. Bootstrap — service accounts и backend
cd 01-bootstrap
cp personal.auto.tfvars.example personal.auto.tfvars
# Заполнить значения: cloud_id, folder_id, oauth_token
terraform init
terraform plan
terraform apply

# 2. Network — VPC, подсети, security groups
cd ../02-network
cp personal.auto.tfvars.example personal.auto.tfvars
terraform init
terraform plan
terraform apply

# 3. Infrastructure — VM, LB, inventory
cd ../03-infrastructure
cp personal.auto.tfvars.example personal.auto.tfvars
terraform init
terraform plan
terraform apply
```

## Конфигурация

Все чувствительные значения хранятся в `personal.auto.tfvars` (добавлен в `.gitignore`). Пример заполнения — в `personal.auto.tfvars.example`.

Основные переменные:

- `cloud_id` — ID облака Yandex Cloud
- `folder_id` — ID каталога
- `zone` — зона доступности (ru-central1-a/b/c)
- `image_id` — ID образа ОС (Debian)
- `master_cpu`, `master_ram`, `master_disk` — ресурсы master-ноды
- `worker_count` — количество worker-нод
- `worker_cpu`, `worker_ram`, `worker_disk` — ресурсы worker-нод

## Outputs

После `terraform apply` модули выводят:

- `01-bootstrap` — ID service accounts
- `02-network` — ID сетей, подсетей, security groups
- `03-infrastructure` — публичные IP нод, ID load balancer, путь к сгенерированному `hosts.yml`

## Очистка

```bash
cd 03-infrastructure && terraform destroy
cd ../02-network && terraform destroy
cd ../01-bootstrap && terraform destroy
```

В обратном порядке — от инфраструктуры к bootstrap.
