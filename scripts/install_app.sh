#!/bin/bash

set -e

# Actualiza el sistema
sudo apt update && sudo apt upgrade -y

# Instala dependencias
sudo apt install -y nginx curl unzip

# Configura Nginx como una app de ejemplo
cat <<EOL | sudo tee /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>App Server</title>
</head>
<body>
    <h1>Hola desde $(hostname)</h1>
</body>
</html>
EOL

# Configura Nginx
cat <<EOL | sudo tee /etc/nginx/sites-available/default
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.html;
}
EOL

# Habilita y reinicia Nginx
sudo systemctl enable nginx
sudo systemctl restart nginx

# Verifica el estado de Nginx
sudo systemctl status nginx --no-pager

# Instala Consul
CONSUL_VERSION="1.15.0"
curl -O https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
sudo unzip consul_${CONSUL_VERSION}_linux_amd64.zip -d /usr/local/bin/
rm consul_${CONSUL_VERSION}_linux_amd64.zip

# Crea usuario y directorios de Consul
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir -p /etc/consul.d /var/lib/consul
sudo chown -R consul:consul /etc/consul.d /var/lib/consul

# Configura Consul como agente cliente
cat <<EOL | sudo tee /etc/consul.d/consul.hcl
client_addr = "0.0.0.0"
data_dir = "/var/lib/consul"
retry_join = ["192.168.100.11"]
EOL

# Crea el servicio systemd para Consul
cat <<EOL | sudo tee /etc/systemd/system/consul.service
[Unit]
Description=Consul Agent
After=network.target

[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -data-dir=/var/lib/consul -config-dir=/etc/consul.d
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# Habilita y arranca Consul
sudo systemctl enable consul
sudo systemctl start consul

# Verifica el estado de Consul
sudo systemctl status consul --no-pager