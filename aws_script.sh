#!/bin/bash

# Your AWS region
AWS_REGION="us-east-1"
username="ubuntu"

vpc=$(aws ec2 create-vpc --cidr-block "20.20.0.0/16" --region $AWS_REGION --output yaml)
vpc_id=$(echo "$vpc" | grep VpcId | sed 's/://g;s/ //g;s/VpcId//g;')
echo "VPC created with ID: $vpc_id"

aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support "{\"Value\":true}" --output yaml >/dev/null
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}" --output yaml >/dev/null
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=poridhi-vpc --output yaml
echo "DNS hostnames enabled for VPC."

internet_gateway=$(aws ec2 create-internet-gateway --region $AWS_REGION --output yaml)
igw_id=$(echo "$internet_gateway" | grep InternetGatewayId | sed 's/://g;s/ //g;s/InternetGatewayId//g;')
aws ec2 create-tags --resources $igw_id --tags Key=Name,Value=poridhi-igw --output yaml >/dev/null
echo "Internet Gateway created with ID: $igw_id"

aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id --output yaml >/dev/null
echo "Internet Gateway attached to VPC."

public_subnet_a=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block "20.20.1.0/24" --availability-zone ${AWS_REGION}a --region $AWS_REGION --output yaml)
public_subnet_a_id=$(echo "$public_subnet_a" | grep SubnetId | sed 's/://g;s/ //g;s/SubnetId//g;')
aws ec2 create-tags --resources $public_subnet_a_id --tags Key=Name,Value=poridhi-public-subnet-a --output yaml >/dev/null
echo "Public Subnet A created with ID: $public_subnet_a_id"

public_subnet_b=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block "20.20.2.0/24" --availability-zone ${AWS_REGION}b --region $AWS_REGION --output yaml)
public_subnet_b_id=$(echo "$public_subnet_b" | grep SubnetId | sed 's/://g;s/ //g;s/SubnetId//g;')
aws ec2 create-tags --resources $public_subnet_b_id --tags Key=Name,Value=poridhi-public-subnet-b --output yaml >/dev/null
echo "Public Subnet B created with ID: $public_subnet_b_id"

public_route_table=$(aws ec2 create-route-table --vpc-id $vpc_id --region $AWS_REGION --output yaml)
public_route_table_id=$(echo "$public_route_table" | grep RouteTableId | sed 's/://g;s/ //g;s/RouteTableId//g;')
aws ec2 create-tags --resources $public_route_table_id --tags Key=Name,Value=poridhi-public-route-table --output yaml >/dev/null
echo "Public Route Table created with ID: $public_route_table_id"

aws ec2 associate-route-table --subnet-id $public_subnet_a_id --route-table-id $public_route_table_id --output yaml >/dev/null
aws ec2 associate-route-table --subnet-id $public_subnet_b_id --route-table-id $public_route_table_id --output yaml >/dev/null
aws ec2 create-route --route-table-id $public_route_table_id --destination-cidr-block "0.0.0.0/0" --gateway-id $igw_id --region $AWS_REGION --output yaml >/dev/null
echo "Internet Gateway route added to Public Route Table for Internet access & Public Route table associate to Public Subnet A & B."

elastic_ip=$(aws ec2 allocate-address --domain vpc --output yaml)
elastic_ip_id=$(echo "$elastic_ip" | grep AllocationId | sed 's/://g;s/ //g;s/AllocationId//g;')
aws ec2 create-tags --resources $elastic_ip_id --tags Key=Name,Value=poridhi-elastic-ip-for-nat-gateway --output yaml >/dev/null
echo "Elastic IP for Nat gateway created with ID: " $elastic_ip_id

nat_gatway=$(aws ec2 create-nat-gateway --subnet-id $public_subnet_b_id --allocation-id $elastic_ip_id --output yaml)
nat_gatway_id=$(echo "$nat_gatway" | grep NatGatewayId | sed 's/://g;s/ //g;s/NatGatewayId//g;')
aws ec2 create-tags --resources $nat_gatway_id --tags Key=Name,Value=poridhi-nat-gateway --output yaml >/dev/null
echo "Nat Gateway created with ID:" $nat_gatway_id

private_subnet_a=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block "20.20.3.0/24" --availability-zone ${AWS_REGION}a --region $AWS_REGION --output yaml)
private_subnet_a_id=$(echo "$private_subnet_a" | grep SubnetId | sed 's/://g;s/ //g;s/SubnetId//g;')
aws ec2 create-tags --resources $private_subnet_a_id --tags Key=Name,Value=poridhi-private-subnet-a --output yaml >/dev/null
echo "Private Subnet A created with ID: $private_subnet_a_id"

private_route_table=$(aws ec2 create-route-table --vpc-id $vpc_id --region $AWS_REGION --output yaml)
private_route_table_id=$(echo "$private_route_table" | grep RouteTableId | sed 's/://g;s/ //g;s/RouteTableId//g;')
aws ec2 create-tags --resources $private_route_table_id --tags Key=Name,Value=poridhi-private-a-route-table --output yaml >/dev/null
echo "Private A Route Table created with ID: $private_route_table_id"

aws ec2 associate-route-table --subnet-id $private_subnet_a_id --route-table-id $private_route_table_id --output yaml >/dev/null
aws ec2 create-route --route-table-id $private_route_table_id --destination-cidr-block "0.0.0.0/0" --nat-gateway-id $nat_gatway_id --region $AWS_REGION --output yaml >/dev/null
echo "Nat Gateway route added to Private A Route Table for Internet access & Privat Route Table A associate to Private Subnet A"

aws ec2 create-key-pair --key-type ed25519 --key-name poridhi --query 'KeyMaterial' --output text >poridhi.pem
echo "Poridhi key pair create"

chmod 400 poridhi.pem

sg_database=$(aws ec2 create-security-group --group-name "poridhi-database-sg" --description "poridhi-database-sg-for-vpc" --vpc-id $vpc_id --output yaml)
sg_database_id=$(echo "$sg_database" | grep GroupId | sed 's/://g;s/ //g;s/GroupId//g;')
aws ec2 create-tags --resources $sg_database_id --tags Key=Name,Value=poridhi-database-sg --output json
aws ec2 authorize-security-group-ingress --group-id $sg_database_id --protocol icmp --port -1 --cidr "0.0.0.0/0" --output yaml >/dev/null
aws ec2 authorize-security-group-ingress --group-id $sg_database_id --protocol tcp --port 3306 --cidr "20.20.0.0/16" --output yaml >/dev/null
aws ec2 authorize-security-group-ingress --group-id $sg_database_id --protocol tcp --port 22 --cidr "20.20.0.0/16" --output yaml >/dev/null
echo "Database security group create with ID: $sg_database_id"

database_vm=$(aws ec2 run-instances \
    --image-id ami-053b0d53c279acc90 \
    --instance-type t2.micro \
    --subnet-id $private_subnet_a_id \
    --key-name poridhi \
    --security-group-ids $sg_database_id \
    --region $AWS_REGION \
    --user-data file://./db_script.sh \
    --output yaml)
database_vm_id=$(echo "$database_vm" | grep InstanceId | sed 's/://g;s/ //g;s/InstanceId//g;')
aws ec2 create-tags --resources $database_vm_id --tags Key=Name,Value=poridhi-database --output yaml >/dev/null
echo "Database VM create with ID: $database_vm_id"

sg_load_balancer=$(aws ec2 create-security-group --group-name "poridhi-load-balancer-sg" --description "poridhi-load-balancer-sg-for-vpc" --vpc-id $vpc_id --output yaml)
sg_load_balancer_id=$(echo "$sg_load_balancer" | grep GroupId | sed 's/://g;s/ //g;s/GroupId//g;')
aws ec2 create-tags --resources $sg_load_balancer_id --tags Key=Name,Value=poridhi-load-balancer-sg --output json
aws ec2 authorize-security-group-ingress --group-id $sg_load_balancer_id --protocol icmp --port -1 --cidr "0.0.0.0/0" --output yaml >/dev/null
aws ec2 authorize-security-group-ingress --group-id $sg_load_balancer_id --protocol tcp --port 80 --cidr "0.0.0.0/0" --output yaml >/dev/null
aws ec2 authorize-security-group-ingress --group-id $sg_load_balancer_id --protocol tcp --port 443 --cidr "0.0.0.0/0" --output yaml >/dev/null
aws ec2 authorize-security-group-ingress --group-id $sg_load_balancer_id --protocol tcp --port 22 --cidr "0.0.0.0/0" --output yaml >/dev/null
echo "Load Balancer security group create with ID: $sg_load_balancer_id"

load_balancer_vm=$(aws ec2 run-instances \
    --image-id ami-053b0d53c279acc90 \
    --instance-type t2.micro \
    --subnet-id $public_subnet_a_id \
    --key-name poridhi \
    --security-group-ids $sg_load_balancer_id \
    --associate-public-ip-address \
    --region $AWS_REGION \
    --user-data file://./lb_script.sh \
    --output yaml)

load_balancer_vm_id=$(echo "$load_balancer_vm" | grep InstanceId | sed 's/://g;s/ //g;s/InstanceId//g;')
aws ec2 create-tags --resources $load_balancer_vm_id --tags Key=Name,Value=poridhi-load-balancer --output yaml >/dev/null
echo "Load balancer VM create with ID: $load_balancer_vm_id"

sg_application=$(aws ec2 create-security-group --group-name "poridhi-application-sg" --description "poridhi-application-sg-for-vpc" --vpc-id $vpc_id --output yaml)
sg_application_id=$(echo "$sg_application" | grep GroupId | sed 's/://g;s/ //g;s/GroupId//g;')
aws ec2 create-tags --resources $sg_application_id --tags Key=Name,Value=poridhi-application-sg --output json
aws ec2 authorize-security-group-ingress --group-id $sg_application_id --protocol icmp --port -1 --cidr "0.0.0.0/0" --output yaml >/dev/null
aws ec2 authorize-security-group-ingress --group-id $sg_application_id --protocol tcp --port 8000 --cidr "20.20.0.0/16" --output yaml >/dev/null
aws ec2 authorize-security-group-ingress --group-id $sg_application_id --protocol tcp --port 3000 --cidr "20.20.0.0/16" --output yaml >/dev/null
aws ec2 authorize-security-group-ingress --group-id $sg_application_id --protocol tcp --port 22 --cidr "0.0.0.0/16" --output yaml >/dev/null
echo "Application security group create with ID: $sg_application_id"

application_vm=$(aws ec2 run-instances \
    --image-id ami-053b0d53c279acc90 \
    --instance-type t2.micro \
    --subnet-id $public_subnet_a_id \
    --key-name poridhi \
    --security-group-ids $sg_application_id \
    --associate-public-ip-address \
    --region $AWS_REGION \
    --user-data file://./application_script.sh \
    --output yaml)

application_vm_id=$(echo "$application_vm" | grep InstanceId | sed 's/://g;s/ //g;s/InstanceId//g;')
aws ec2 create-tags --resources $application_vm_id --tags Key=Name,Value=poridhi-application --output yaml >/dev/null
echo "Load balancer VM create with ID: $application_vm_id"

echo "Installing Nginx web server to load-balancer VM... please wait 5 minutes"

load_balancer_public_public_ip=$(echo "$load_balancer_vm" | grep PublicIpAddress | sed 's/://g;s/ //g;s/PublicIpAddress//g;')
application_private_ip=$(echo "$load_balancer_vm" | grep PrivateIpAddress | sed 's/://g;s/ //g;s/PrivateIpAddress//g;')

# echo "\n\n"
# echo "Set the DNS A record -> students.poridhi.com : $load_balancer_public_public_ip"
# echo "Set the DNS A record -> api.students.poridhi.com : $load_balancer_public_public_ip"
# echo "\n\n"
# echo "use a web browser to open the page  http://$load_balancer_public_public_ip"
