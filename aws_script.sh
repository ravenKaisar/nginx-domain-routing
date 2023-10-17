#!/bin/bash

# Your AWS region
AWS_REGION="us-east-1"
username="ubuntu"

vpc_id=$(aws ec2 create-vpc --cidr-block "20.20.0.0/16" --region $AWS_REGION --output json --query 'Vpc.VpcId')
vpc_id=$(echo "$vpc_id" | sed 's/"//g')
echo "VPC created with ID: $vpc_id"

aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support "{\"Value\":true}" --output json
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}" --output json
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=poridhi-vpc --output json
echo "DNS hostnames enabled for VPC."

gateway_id=$(aws ec2 create-internet-gateway --region $AWS_REGION --output json --query 'InternetGateway.InternetGatewayId')
gateway_id=$(echo "$gateway_id" | sed 's/"//g')
aws ec2 create-tags --resources $gateway_id --tags Key=Name,Value=poridhi-igw --output json
echo "Internet Gateway created with ID: $gateway_id"

aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $gateway_id --output json
echo "Internet Gateway attached to VPC."

public_subnet_a=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block "20.20.1.0/24" --availability-zone ${AWS_REGION}a --region $AWS_REGION --output json --query 'Subnet.SubnetId')
public_subnet_a=$(echo "$public_subnet_a" | sed 's/"//g')
aws ec2 create-tags --resources $public_subnet_a --tags Key=Name,Value=poridhi-public-subnet-a --output json
echo "Public Subnet A created with ID: $public_subnet_a"

public_subnet_b=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block "20.20.2.0/24" --availability-zone ${AWS_REGION}b --region $AWS_REGION --output json --query 'Subnet.SubnetId')
public_subnet_b=$(echo "$public_subnet_b" | sed 's/"//g')
aws ec2 create-tags --resources $public_subnet_b --tags Key=Name,Value=poridhi-public-subnet-b --output json
echo "Public Subnet B created with ID: $public_subnet_b"

route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --region $AWS_REGION --output json --query 'RouteTable.RouteTableId')
route_table_id=$(echo "$route_table_id" | sed 's/"//g')
route_tag=$(aws ec2 create-tags --resources $route_table_id --tags Key=Name,Value=poridhi-public-route-table --output json)
echo "Public Route Table created with ID: $route_table_id"

assign_igw=$(aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block "0.0.0.0/0" --gateway-id $gateway_id --output json --region $AWS_REGION --query 'Return')
associate_route_table=$(aws ec2 associate-route-table --subnet-id $public_subnet_a --route-table-id $route_table_id --output json)
associate_route_table=$(aws ec2 associate-route-table --subnet-id $public_subnet_b --route-table-id $route_table_id --output json)
echo "IGW route added to Public Route Table for Internet access & Route table associate to Public Subnet A & B."

private_subnet_a=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block "20.20.3.0/24" --availability-zone ${AWS_REGION}a --region $AWS_REGION --output json --query 'Subnet.SubnetId')
private_subnet_a=$(echo "$private_subnet_a" | sed 's/"//g')
route_tag=$(aws ec2 create-tags --resources $private_subnet_a --tags Key=Name,Value=poridhi-private-subnet-a --output json)
echo "Private Subnet A created with ID: $private_subnet_a"

private_route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --region $AWS_REGION --output json --query 'RouteTable.RouteTableId')
private_route_table_id=$(echo "$private_route_table_id" | sed 's/"//g')
route_tag=$(aws ec2 create-tags --resources $private_route_table_id --tags Key=Name,Value=poridhi-private-a-route-table --output json)
echo "Private A Route Table created with ID: $route_table_id"

elastic_ip_for_nat_gateway_id=$(aws ec2 allocate-address --domain vpc --output json --query 'AllocationId')
elastic_ip_for_nat_gateway_id=$(echo "$elastic_ip_for_nat_gateway_id" | sed 's/"//g')
route_tag=$(aws ec2 create-tags --resources $elastic_ip_for_nat_gateway_id --tags Key=Name,Value=poridhi-elastic-ip-for-nat-gateway --output json)
echo "Elastic IP for Nat gateway created with ID: " $elastic_ip_for_nat_gateway_id

nat_gatway_id=$(aws ec2 create-nat-gateway --subnet-id $public_subnet_b --allocation-id $elastic_ip_for_nat_gateway_id --output json --query 'NatGateway.NatGatewayId')
nat_gatway_id=$(echo "$nat_gatway_id" | sed 's/"//g')
route_tag=$(aws ec2 create-tags --resources $nat_gatway_id --tags Key=Name,Value=poridhi-nat-gateway --output json)
echo "Nat Gateway created with ID:" $nat_gatway_id

assign_igw=$(aws ec2 create-route --route-table-id $private_route_table_id --destination-cidr-block "0.0.0.0/0" --nat-gateway-id $nat_gatway_id --output json --region $AWS_REGION --query 'Return')
associate_route_table=$(aws ec2 associate-route-table --subnet-id $private_subnet_a --route-table-id $private_route_table_id --output json)
echo "Nat Gateway route added to Private A Route Table for Internet access & Route table associate to Private Subnet A"

aws ec2 create-key-pair --key-name poridhi --query 'KeyMaterial' --output text >poridhi.pem
echo "Poridhi key pair create"

chmod 400 poridhi.pem

sg_lb_id=$(aws ec2 create-security-group --group-name "poridhi-lb-sg" --description "poridhi-lb-sg-for-vpc" --vpc-id $vpc_id --output json --query 'GroupId')
sg_lb_id=$(echo "$sg_lb_id" | sed 's/"//g')
aws ec2 create-tags --resources $sg_lb_id --tags Key=Name,Value=poridhi-lb-sg --output json
sg_icmp=$(aws ec2 authorize-security-group-ingress --group-id $sg_lb_id --protocol icmp --port -1 --cidr "0.0.0.0/0" --output json --query 'Return')
sg_http=$(aws ec2 authorize-security-group-ingress --group-id $sg_lb_id --protocol tcp --port 80 --cidr "0.0.0.0/0" --output json --query 'Return')
sg_https=$(aws ec2 authorize-security-group-ingress --group-id $sg_lb_id --protocol tcp --port 443 --cidr "0.0.0.0/0" --output json --query 'Return')
sg_ssh=$(aws ec2 authorize-security-group-ingress --group-id $sg_lb_id --protocol tcp --port 22 --cidr "0.0.0.0/0" --output json --query 'Return')
echo "load-balancer security group create with ID: $sg_lb_id"

instance_lb_id=$(aws ec2 run-instances \
    --image-id ami-053b0d53c279acc90 \
    --instance-type t2.micro \
    --subnet-id $public_subnet_a \
    --key-name poridhi \
    --security-group-ids $sg_lb_id \
    --associate-public-ip-address \
    --region $AWS_REGION \
    --output json \
    --query 'Instances[0].InstanceId')

instance_lb_id=$(echo "$instance_lb_id" | sed 's/"//g')
aws ec2 create-tags --resources $instance_lb_id --tags Key=Name,Value=poridhi-lb --output json
echo "Load balancer VM create with ID: $instance_lb_id"

sg_application_id=$(aws ec2 create-security-group --group-name "poridhi-application-sg" --description "poridhi-application-sg-for-vpc" --vpc-id $vpc_id --output json --query 'GroupId')
sg_application_id=$(echo "$sg_application_id" | sed 's/"//g')
aws ec2 create-tags --resources $sg_application_id --tags Key=Name,Value=poridhi-application-sg --output json
sg_icmp=$(aws ec2 authorize-security-group-ingress --group-id $sg_application_id --protocol icmp --port -1 --cidr "0.0.0.0/0" --output json --query 'Return')
sg_backend=$(aws ec2 authorize-security-group-ingress --group-id $sg_application_id --protocol tcp --port 8000 --cidr "20.20.0.0/16" --output json --query 'Return')
sg_frontend=$(aws ec2 authorize-security-group-ingress --group-id $sg_application_id --protocol tcp --port 3000 --cidr "20.20.0.0/16" --output json --query 'Return')
sg_ssh=$(aws ec2 authorize-security-group-ingress --group-id $sg_application_id --protocol tcp --port 22 --cidr "20.20.0.0/16" --output json --query 'Return')
echo "application security group create with ID: $sg_application_id"

instance_application_id=$(aws ec2 run-instances \
    --image-id ami-053b0d53c279acc90 \
    --instance-type t2.micro \
    --subnet-id $public_subnet_a \
    --key-name poridhi \
    --security-group-ids $sg_application_id \
    --associate-public-ip-address \
    --region $AWS_REGION \
    --output json \
    --query 'Instances[0].InstanceId')

instance_application_id=$(echo "$instance_application_id" | sed 's/"//g')
aws ec2 create-tags --resources $instance_application_id --tags Key=Name,Value=poridhi-application --output json
echo "Application VM create with ID: $instance_application_id"

sg_database_id=$(aws ec2 create-security-group --group-name "poridhi-database-sg" --description "poridhi-database-sg-for-vpc" --vpc-id $vpc_id --output json --query 'GroupId')
sg_database_id=$(echo "$sg_database_id" | sed 's/"//g')
aws ec2 create-tags --resources $sg_database_id --tags Key=Name,Value=poridhi-database-sg --output json
sg_icmp=$(aws ec2 authorize-security-group-ingress --group-id $sg_database_id --protocol icmp --port -1 --cidr "0.0.0.0/0" --output json --query 'Return')
sg_postgres=$(aws ec2 authorize-security-group-ingress --group-id $sg_database_id --protocol tcp --port 5432 --cidr "20.20.0.0/16" --output json --query 'Return')
sg_ssh=$(aws ec2 authorize-security-group-ingress --group-id $sg_database_id --protocol tcp --port 22 --cidr "20.20.0.0/16" --output json --query 'Return')
echo "database security group create with ID: $sg_database_id"

instance_database_id=$(aws ec2 run-instances \
    --image-id ami-053b0d53c279acc90 \
    --instance-type t2.micro \
    --subnet-id $private_subnet_a \
    --key-name poridhi \
    --security-group-ids $sg_database_id \
    --region $AWS_REGION \
    --output json \
    --query 'Instances[0].InstanceId')

instance_database_id=$(echo "$instance_database_id" | sed 's/"//g')
aws ec2 create-tags --resources $instance_database_id --tags Key=Name,Value=poridhi-database --output json
echo "Database VM create with ID: $instance_application_id"

echo "Installing Nginx web server to load-balancer VM... please wait 5 minutes"
lb_instance_public_ip=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids $instance_lb_id --output json --query 'Reservations[0].Instances[0].PublicIpAddress')
# lb_instance_public_ip=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids i-0bbb9994b60ebeeea --output json --query 'Reservations[0].Instances[0].PublicIpAddress')
lb_instance_public_ip=$(echo "$lb_instance_public_ip" | sed 's/"//g')

application_instance_private_ip=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids $instance_application_id --output json --query 'Reservations[0].Instances[0].PrivateIpAddress')
# application_instance_private_ip=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids i-02dca31304cd650a1 --output json --query 'Reservations[0].Instances[0].PrivateIpAddress')
application_instance_private_ip=$(echo "$application_instance_private_ip" | sed 's/"//g')

sh lb_script.sh $username $lb_instance_public_ip $application_instance_private_ip

echo "\n\n"
echo "Set the DNS A record -> students.poridhi.com : $lb_instance_public_ip"
echo "Set the DNS A record -> api.students.poridhi.com : $lb_instance_public_ip"
echo "\n\n"
echo "use a web browser to open the page  http://$lb_instance_public_ip"
