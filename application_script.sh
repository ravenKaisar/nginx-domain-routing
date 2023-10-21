#!/bin/bash

# Add Docker's official GPG key:
sudo apt-get update -y
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg -y

# Add the repository to Apt sources:
echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update -y

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo docker run --name frontend -d \
    -p 3000:3000 \
    --restart unless-stopped \
    docker.pkg.github.com/ravenkaisar/nginx-domain-routing/distributed:react

sudo docker run --name backend -d \
    -e MYSQL_HOST=127.0.0.1 \
    -e MYSQL_USERNAME=root \
    -e MYSQL_PASSWORD=123456 \
    -e MYSQL_DATABASE=express \
    -e MYSQL_PORT=3307 \
    -e PORT=8000 \
    -p 8000:8000 \
    --restart unless-stopped \
    docker.pkg.github.com/ravenkaisar/nginx-domain-routing/distributed:api
