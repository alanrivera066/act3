provider "aws" {
  region = "us-east-1"
}

# --- VPC ---
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.10.0.0/20"
  tags = {
    Name = "VPC-Terraform"
  }
}

# --- Subred pública ---
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.10.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subred-Publica"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "IGW"
  }
}

# --- Tabla de rutas pública ---
resource "aws_route_table" "public_routes" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public-RT"
  }
}

resource "aws_route_table_association" "assoc_public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_routes.id
}

# --- Grupos de Seguridad ---

# SG - Jump Server (SSH desde Internet)
resource "aws_security_group" "sg_jump" {
  name        = "SG_Jump"
  description = "Permite SSH desde Internet"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Jump"
  }
}

# SG - Web Servers (HTTP desde Internet, SSH solo desde Jump)
resource "aws_security_group" "sg_web" {
  name        = "SG_Web"
  description = "Permite HTTP desde Internet y SSH desde Jump Server"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_jump.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Web"
  }
}

# --- Instancia Jump Server ---
resource "aws_instance" "jump_server" {
  ami                         = "ami-00a929b66ed6e0de6" # Amazon Linux 2023
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.sg_jump.id]
  associate_public_ip_address = true
  key_name                    = "vockey"

  tags = {
    Name = "Jump-Server"
  }
}

# --- Instancias Web Servers ---
resource "aws_instance" "web_server" {
  count                       = 4
  ami                         = "ami-00a929b66ed6e0de6" # Amazon Linux 2023
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.sg_web.id]
  associate_public_ip_address = true
  key_name                    = "vockey"

  tags = {
    Name = "Web-Server-${count.index + 1}"
  }
}

# --- Outputs ---
output "jump_server_ip" {
  value = aws_instance.jump_server.public_ip
}

output "web_servers_ips" {
  value = [for instance in aws_instance.web_server : instance.public_ip]
}
