provider "aws" {
region = "us-east-1"
}

#Crear VPC
resource "aws_vpc" "Mi_vpc" {
cidr_block = "10.0.0.0/16" #ip de la vpc del diagrama

tags = {
Name = "VPC-TERRAFORM"
}
}

#Crear subred publica
resource "aws_subnet" "subred_publica" {
vpc_id = aws_vpc.Mi_vpc.id # Cambié 'mi_vpc' a 'Mi_vpc'
cidr_block = "10.0.0.0/24"
map_public_ip_on_launch = true

tags = {
Name = "Guacholo_publica"
}
}

resource "aws_internet_gateway" "igw" {
vpc_id = aws_vpc.Mi_vpc.id # Cambié 'mi_vpc' a 'Mi_vpc'

tags = {
Name = "IGW-Terraform"
}
}

resource "aws_route_table" "tabla_rutas_publicas" {
vpc_id = aws_vpc.Mi_vpc.id # Cambié 'mi_vpc' a 'Mi_vpc'

route {
cidr_block = "0.0.0.0/0" #Permitir salida a internet
gateway_id = aws_internet_gateway.igw.id
}

tags = {
Name = "Tabla_Rutas_publicas"
}
}

#Asociación de tablas de rutas a subred pública
resource "aws_route_table_association" "asosiacion_rutas" {
subnet_id = aws_subnet.subred_publica.id
route_table_id = aws_route_table.tabla_rutas_publicas.id
}

#Creación de grupo de seguridad
resource "aws_security_group" "sg-publico" {
vpc_id = aws_vpc.Mi_vpc.id # Cambié 'mi_vpc' a 'Mi_vpc'
name = "Grupo-Seguridad_Terraform-Publico"
description = "Grupo de seguridad para conectarme al servidor linux por SSH desde Terraform"

# Permitir tráfico SSH desde cualquier IP
ingress {
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

# Permitir tráfico HTTP desde cualquier IP
ingress {
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_instance" "mi_instancia" {
ami = "ami-00a929b66ed6e0de6" # Ami de Amazon Linux
instance_type = "t2.micro"
subnet_id = aws_subnet.subred_publica.id
# Especificando en qué subred se va a crear la instancia
vpc_security_group_ids = [aws_security_group.sg-publico.id]
associate_public_ip_address = true

tags = {
Name = "Servidor Linux - Terraform con SG"
}
}

output "public_ip" {
description = "IP publica de la instancia Linux"
value = aws_instance.mi_instancia.public_ip
}