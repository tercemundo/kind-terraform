# Instalación Automática de Cluster KIND con Terraform

 Este script automatiza la instalación completa de un cluster Kubernetes local usando KIND (Kubernetes in Docker) con 3 nodos: 1 control-plane y 2 workers.

## Prerequisitos Sistema operativo Ubuntu/Debian

Explicación del Script Paso a Paso

1. Configuración Inicial

Instalo todos los paquetes que vaya a necesitar.

```jsx
echo "=========================================="
echo "Instalando dependencias del sistema"
echo "=========================================="

# Actualizar repositorios e instalar snapd
sudo apt update
sudo apt install snapd -y

echo "=========================================="
echo "Instalando kubectl desde snap"
echo "=========================================="

sudo snap install kubectl --classic
kubectl version --client

echo "=========================================="
echo "Instalando Terraform desde snap"
echo "=========================================="

sudo snap install terraform --classic
terraform -version

echo "=========================================="
echo "Instalando KIND"
echo "=========================================="

# Descargar e instalar KIND
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64
```

 Finalmente, creo los ficheros de configuracion, bajando también el proveedor.

```jsx
mkdir -p ~/kind-cluster-terraform
cd ~/kind-cluster-terraform

# Crear providers.tf
cat > providers.tf <<'EOF'
terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.5.1"
    }
  }
}

provider "kind" {}
EOF

# Crear main.tf
cat > main.tf <<'EOF'
resource "kind_cluster" "default" {
  name            = "my-cluster"
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      
      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }

    node {
      role = "worker"
    }

    node {
      role = "worker"
    }
  }
}
EOF

# Crear outputs.tf
cat > outputs.tf <<'EOF'
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
EOF

echo "=========================================="
echo "Inicializando Terraform"
echo "=========================================="

terraform init

echo "=========================================="
echo "Aplicando configuración de Terraform"
echo "=========================================="

terraform apply -auto-approve

echo "=========================================="
echo "Configurando kubeconfig"
echo "=========================================="

# Crear directorio .kube si no existe
mkdir -p ~/.kube

# Exportar kubeconfig
kind export kubeconfig --name=my-cluster

echo "=========================================="
echo "Verificando el cluster"
echo "=========================================="

# Esperar un momento para que los nodos estén listos
sleep 10

kubectl get nodes

echo "=========================================="
echo "¡Instalación completada!"
echo "=========================================="
echo ""
echo "Tu cluster KIND está listo con:"
echo "- 1 nodo control-plane"
echo "- 2 nodos workers"
echo ""
echo "Puedes verificar el estado con:"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo ""
echo "IMPORTANTE: Cierra sesión y vuelve a iniciarla"
echo "para que los permisos de Docker surtan efecto,"
echo "o ejecuta: newgrp docker"
echo "=========================================="
```

###Ficheros generados
main.tf
```
resource "kind_cluster" "default" {
  name            = "my-cluster"
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      
      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }

    node {
      role = "worker"
    }

    node {
      role = "worker"
    }
  }
}

```
providers.tf
```
terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.5.1"
    }
  }
}

provider "kind" {}
```
y outputs.tf

```
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
```
