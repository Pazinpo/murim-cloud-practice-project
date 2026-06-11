# 1. Provider (AWS 서울 리전)
provider "aws" {
  region = "ap-northeast-2"
}

# 2. VPC
resource "aws_vpc" "murim_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Murim-Cloud-VPC"
  }
}

# 3. Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.murim_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Murim-Public-Subnet"
  }
}

# 4. Internet Gateway
resource "aws_internet_gateway" "murim_igw" {
  vpc_id = aws_vpc.murim_vpc.id
  tags = {
    Name = "Murim-IGW"
  }
}

# 5. Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.murim_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.murim_igw.id
  }
  tags = {
    Name = "Murim-Public-RT"
  }
}

# 6. Route Table Association
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 7. Security Group
resource "aws_security_group" "murim_sg" {
  name   = "murim-sg"
  vpc_id = aws_vpc.murim_vpc.id

  # SSH (22) - 본인 IP만
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["183.102.82.167/32"]
  }

  # HTTP (80) - 웹 서비스 공개
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Nginx (8085) - 웹 서비스 공개
  ingress {
    from_port   = 8085
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MariaDB (3306) - 본인 IP만
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["183.102.82.167/32"]
  }

  # Grafana (3000) - 본인 IP만
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["183.102.82.167/32"]
  }

  # Prometheus (9090) - 본인 IP만
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["183.102.82.167/32"]
  }

  # cAdvisor (8081) - 본인 IP만
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["183.102.82.167/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Murim-SG"
  }
}

# 8. EC2 Instance
resource "aws_instance" "murim_server" {
  ami                    = "ami-040c33c6a51fd5d96"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.murim_sg.id]
  key_name               = "murim-key"

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-USERDATA
#!/bin/bash
set -e
apt-get update -y
apt-get install -y docker.io docker-compose-v2 git
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# 스왑 2GB (micro 메모리 대응)
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 프로젝트 클론 & .env 생성 & 기동
cd /home/ubuntu
git clone https://github.com/Pazinpo/murim-cloud-practice-project.git
cd murim-cloud-practice-project
cat > .env <<'ENVEOF'
MYSQL_ROOT_PASSWORD=1234
DB_PASSWORD=1234
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin1234
ENVEOF
docker compose up -d
USERDATA

  user_data_replace_on_change = true

  tags = {
    Name = "Murim-Terraform-Server"
  }
}

# 9. Output
output "server_public_ip" {
  value = aws_instance.murim_server.public_ip
}
