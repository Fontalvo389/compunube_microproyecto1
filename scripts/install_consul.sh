#!/bin/bash

set -e

# Actualiza el sistema
sudo apt update && sudo apt upgrade -y

# Instala dependencias
sudo apt install -y unzip curl

# Descarga e instala Consul
CONSUL_VERSION="1.15.0"
curl -O https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
sudo unzip consul_${CONSUL_VERSION}_linux_amd64.zip -d /usr/local/bin/
rm consul_${CONSUL_VERSION}_linux_amd64.zip

# Crea el usuario y directorios de Consul
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir -p /etc/consul.d /var/lib/consul
sudo chown -R consul:consul /etc/consul.d /var/lib/consul

# Configura Consul
cat <<EOL | sudo tee /etc/consul.d/consul.hcl
server = true
bootstrap_expect = 1
data_dir = "/var/lib/consul"
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
ui = true

# Habilita la API HTTP
addresses {
  http = "0.0.0.0"
}
EOL

# Crea el servicio systemd para Consul
cat <<EOL | sudo tee /etc/systemd/system/consul.service
[Unit]
Description=Consul Agent
After=network.target

[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -server -bootstrap-expect=1 -data-dir=/var/lib/consul -config-dir=/etc/consul.d
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# Habilita y arranca Consul
sudo systemctl enable consul
sudo systemctl start consul

# Verifica el estado de Consul
sudo systemctl status consul --no-pager