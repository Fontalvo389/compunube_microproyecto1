#!/bin/bash

set -e

# Actualiza el sistema
sudo apt update && sudo apt upgrade -y

# Instala HAProxy
sudo apt install -y haproxy

# Configura HAProxy
cat <<EOL | sudo tee /etc/haproxy/haproxy.cfg
frontend http_front
    bind *:80
    default_backend app_back

backend app_back
    balance roundrobin
    server app1 192.168.100.21:80 check
    server app2 192.168.100.22:80 check
    server app3 192.168.100.23:80 check
EOL

# Habilita y reinicia HAProxy
sudo systemctl enable haproxy
sudo systemctl restart haproxy

# Verifica el estado de HAProxy
sudo systemctl status haproxy --no-pager