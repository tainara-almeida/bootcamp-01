# main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.63.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.63.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# --- Rede VPC ---
# Uma rede dedicada para isolar os recursos da nossa demonstração.

resource "google_compute_network" "main" {
  name                    = "gke-modernization-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "gke-modernization-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.main.id
}

# --- Meta 1: Containerização e Gerenciamento (GKE Autopilot) ---

resource "google_container_cluster" "autopilot_cluster" {
  provider           = google-beta
  name               = "${var.cluster_name_prefix}-autopilot-cluster"
  location           = var.region
  enable_autopilot   = true
  network            = google_compute_network.main.id
  subnetwork         = google_compute_subnetwork.main.id
  release_channel {
    channel = "REGULAR"
  }
}

# --- Meta 2: Segurança e Proteção de Borda (Cloud Armor) ---

resource "google_compute_security_policy" "armor_policy" {
  name = "gke-ingress-armor-policy"
  description = "Política de segurança para o Ingress do GKE"

  # Regra padrão: permite tráfego, mas você pode alterar para deny(403) para testar.
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Regra padrão para permitir todo o tráfego"
  }

  # Exemplo de regra de proteção contra SQL Injection
  rule {
    action   = "deny(403)"
    priority = 1000
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v3.3-stable')"
      }
    }
    description = "Bloquear ataques de SQL Injection"
  }
}

# --- Meta 3: Arquitetura de Mensageria e Cache ---

# Recurso que atende à meta: Arquitetura de Mensageria e Cache (Mensageria)
resource "google_pubsub_topic" "main_topic" {
  name = "birthday-messages-topic"
}

# Recurso que atende à meta: Arquitetura de Mensageria e Cache (Cache)
resource "google_redis_instance" "cache" {
  name           = "gke-demo-redis-cache"
  tier           = "BASIC" # Ideal para demonstração e desenvolvimento
  memory_size_gb = 1
  region         = var.region
  
  # Conecta a instância Redis à nossa VPC
  authorized_network = google_compute_network.main.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  depends_on = [google_service_networking_connection.private_service_access]
}

# --- Meta 4: Banco de Dados Moderno (AlloyDB) ---

# Habilitar APIs necessárias para AlloyDB e Private Service Access
resource "google_project_service" "required_apis" {
  for_each = toset([
    "alloydb.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com"
  ])
  service                    = each.key
  disable_on_destroy         = false
  disable_dependent_services = true
}

# Configuração de Private Service Access, necessária para AlloyDB e Redis
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "alloydb-private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_service_access" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
  depends_on              = [google_project_service.required_apis]
}

# Recurso que atende à meta: Banco de Dados Moderno (AlloyDB)
resource "google_alloydb_cluster" "main_cluster" {
  provider   = google-beta
  project    = var.project_id
  location   = var.region
  cluster_id = "alloydb-main-cluster"
  network    = google_compute_network.main.id

  initial_user {
    user     = "postgres"
    password = random_password.db_password.result
  }

  depends_on = [google_service_networking_connection.private_service_access]
}

resource "google_alloydb_instance" "primary_instance" {
  provider     = google-beta
  cluster      = google_alloydb_cluster.main_cluster.name
  instance_id  = "primary-instance-1"
  instance_type = "PRIMARY"
  machine_config {
    cpu_count = 2
  }
  depends_on = [google_alloydb_cluster.main_cluster]
}

# Gerenciamento seguro da senha do banco de dados
resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "google_secret_manager_secret" "alloydb_password_secret" {
  secret_id = "alloydb-postgres-password"
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "alloydb_password_secret_version" {
  secret      = google_secret_manager_secret.alloydb_password_secret.id
  secret_data = random_password.db_password.result
}
