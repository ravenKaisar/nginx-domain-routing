# !/bin/bash

username="$1"
lb_ip="$2"
application_private_ip="$3"

nginx_file_path="nginx.conf"
nginx_file_content=$(cat "$nginx_file_path")
nginx_new_content=$(echo "$nginx_file_content" | sed "s/private_ip/$application_private_ip/g")
echo "$nginx_new_content" >"$nginx_file_path"

scp -i poridhi.pem nginx.conf $username@$lb_ip:/home/ubuntu

ssh -i poridhi.pem $username@$lb_ip /bin/bash <<'EOT'
# Update package lists
sudo apt update -y

sudo apt install -y nginx
sudo su

mv /home/ubuntu/nginx.conf /etc/nginx
nginx -t
systemctl restart nginx
EOT
