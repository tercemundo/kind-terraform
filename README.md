Instalación Automática de Cluster KIND con Terraform
Este script automatiza la instalación completa de un cluster Kubernetes local usando KIND (Kubernetes in Docker) con 3 nodos: 1 control-plane y 2 workers.​

Prerequisitos
Sistema operativo Ubuntu/Debian

Acceso sudo

Conexión a Internet

Explicación del Script Paso a Paso
1. Configuración Inicial
bash
#!/bin/bash
set -e  # Detener en caso de error
El shebang #!/bin/bash indica que el script se ejecutará con Bash. El comando set -e hace que el script se detenga inmediatamente si cualquier comando falla, evitando errores en cascada.​

2. Instalación de Snapd
bash
sudo apt update
sudo apt install snapd -y
Actualiza los repositorios de paquetes e instala snapd, el gestor de paquetes snap necesario para instalar kubectl y Terraform.​

3. Instalación de kubectl
bash
sudo snap install kubectl --classic
kubectl version --client
Instala kubectl usando snap con el flag --classic, que otorga accesos privilegiados necesarios para la herramienta. Luego verifica la instalación mostrando la versión.​

4. Instalación de Terraform
bash
sudo snap install terraform --classic
terraform -version
Instala Terraform desde snap con permisos clásicos y verifica la instalación.​

5. Instalación de KIND
bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind version
Descarga el binario de KIND desde la URL oficial, le da permisos de ejecución con chmod +x, lo mueve al PATH del sistema (/usr/local/bin) para que esté disponible globalmente, y verifica la instalación.​

6. Verificación e Instalación de Docker
bash
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    sudo apt install docker.io -y
    sudo systemctl start docker
    sudo systemctl enable docker
fi
Verifica si Docker está instalado usando command -v docker. Si no existe, lo instala, inicia el servicio y lo habilita para arranque automático. KIND requiere Docker para funcionar ya que cada nodo del cluster es un contenedor Docker.​

7. Configuración de Permisos Docker
bash
sudo usermod -aG docker $USER
Agrega el usuario actual al grupo docker para que pueda ejecutar comandos docker sin sudo.​

8. Creación de Archivos Terraform
providers.tf
bash
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
Crea el archivo de configuración de providers de Terraform, especificando el provider de KIND versión 0.5.1.​

main.tf
bash
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
    node { role = "worker" }
    node { role = "worker" }
  }
}
EOF
Define el recurso del cluster KIND con:​

name: Nombre del cluster ("my-cluster")

wait_for_ready: Espera a que el cluster esté listo

node control-plane: Nodo maestro con mapeo de puertos 80 y 443 para acceso web

2 nodes worker: Dos nodos trabajadores para ejecutar cargas de trabajo

outputs.tf
bash
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
Define las salidas de Terraform para mostrar información del cluster creado.​

9. Inicialización de Terraform
bash
terraform init
Descarga el provider de KIND y prepara el entorno de Terraform.​

10. Aplicación de la Configuración
bash
terraform apply -auto-approve
Crea el cluster KIND automáticamente sin pedir confirmación manual. Este proceso toma aproximadamente 2 minutos.​

11. Configuración de kubeconfig
bash
mkdir -p ~/.kube
kind export kubeconfig --name=my-cluster
Crea el directorio de configuración de Kubernetes y exporta el kubeconfig del cluster KIND para que kubectl pueda conectarse.​

12. Verificación del Cluster
bash
sleep 10
kubectl get nodes
Espera 10 segundos para que los nodos terminen de inicializarse y luego lista los nodos del cluster.​

Uso
bash
chmod +x setup-kind-cluster.sh
./setup-kind-cluster.sh
Post-Instalación
Después de ejecutar el script, reinicia tu sesión o ejecuta:

bash
newgrp docker
Para aplicar los permisos de Docker.​

Verifica el estado del cluster:

bash
kubectl get nodes
kubectl get pods -A
