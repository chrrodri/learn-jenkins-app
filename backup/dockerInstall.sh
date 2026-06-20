#!/bin/bash

set -euo pipefail

DOCKER_KEYRING="/etc/apt/keyrings/docker.asc"
DOCKER_REPO="/etc/apt/sources.list.d/docker.sources"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

remove_old_packages() {

    info "Eliminando versiones antiguas de Docker..."

    for pkg in docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc; do
        sudo apt remove -y "$pkg" 2>/dev/null || true
    done
}

install_dependencies() {

    info "Instalando dependencias..."

    sudo apt update -y

    sudo apt install -y \
        ca-certificates \
        curl
}

configure_repository() {

    info "Configurando repositorio oficial de Docker..."

    sudo install -m 0755 -d /etc/apt/keyrings

    if [ ! -f "$DOCKER_KEYRING" ]; then
        sudo curl -fsSL \
        https://download.docker.com/linux/ubuntu/gpg \
        -o "$DOCKER_KEYRING"

        sudo chmod a+r "$DOCKER_KEYRING"
    fi

    if [ ! -f "$DOCKER_REPO" ]; then

        sudo tee "$DOCKER_REPO" > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: $DOCKER_KEYRING
EOF

    fi

    sudo apt update -y
}

install_docker() {

    if command -v docker &>/dev/null; then
        success "Docker ya está instalado"
        docker --version
        return
    fi

    info "Instalando Docker Engine..."

    sudo apt install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    sudo systemctl enable docker
    sudo systemctl start docker

    sudo usermod -aG docker "$USER"

    success "Docker instalado correctamente"
}

verify_installation() {

    info "Verificando instalación..."

    docker --version

    docker compose version

    sudo systemctl --no-pager status docker

    info "Ejecutando contenedor de prueba..."

    sudo docker run hello-world

    success "Prueba completada"
}

main() {

    remove_old_packages

    install_dependencies

    configure_repository

    install_docker

    verify_installation

    echo ""
    success "Instalación finalizada correctamente"
    echo ""
    echo "IMPORTANTE:"
    echo "Ejecuta:"
    echo ""
    echo "newgrp docker"
    echo ""
    echo "o cierra sesión y vuelve a iniciarla para aplicar los permisos del grupo docker."
}

main
