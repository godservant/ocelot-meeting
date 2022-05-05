provider "aws" {
  region  = "us-east-2"
  version = "= 3.74.2"
}

terraform {
  required_version = "= 0.14.11"
}

resource "aws_vpc" "sjpoc-vpc" {
  cidr_block           = "10.148.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "sjpoc-vpc"
  }
}

resource "aws_subnet" "sjpoc-pub-subnet" {
  vpc_id            = aws_vpc.sjpoc-vpc.id
  cidr_block        = "10.148.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "sjpoc-pub-subnet"
  }
}

resource "aws_internet_gateway" "sjpoc-ig" {
  vpc_id = aws_vpc.sjpoc-vpc.id

  tags = {
    Name = "sjpoc-ig"
  }
}

resource "aws_route_table" "sjpoc-pub-rt" {
  vpc_id = aws_vpc.sjpoc-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sjpoc-ig.id
  }

  tags = {
    Name = "sjpoc-pub-rt"
  }
}

resource "aws_route_table_association" "public-rt-assoc" {
  subnet_id      = aws_subnet.sjpoc-pub-subnet.id
  route_table_id = aws_route_table.sjpoc-pub-rt.id
}

resource "aws_security_group" "sjpoc-sec-grp" {
  name        = "sjpoc-sec-grp"
  description = "sjpoc-sec-grp"
  vpc_id      = aws_vpc.sjpoc-vpc.id

  ingress {
    description = "sjpoc-ssh-ec2"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["71.236.26.157/32"]
    self        = true
  }

  ingress {
    description = "sjpoc-rdp-ec2"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["71.236.26.157/32"]
    self        = true
  }

  egress {
    description = "Outbound Allowed"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sjpoc-sec-grp"
  }
}

resource "aws_instance" "sjpoc-pub-bastion" {
  ami                         = "ami-0fe23c115c3ba9bac"
  instance_type               = "t2.micro"
  key_name                    = "sj-poc-key"
  vpc_security_group_ids      = [aws_security_group.sjpoc-sec-grp.id]
  subnet_id                   = aws_subnet.sjpoc-pub-subnet.id
  associate_public_ip_address = true

  tags = {
    Name = "sjpoc-pub-bastion"
  }
}
