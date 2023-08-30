
provider "aws" {
  alias = "ap_south"
  region = "ap-south-2"
  access_key="AKIAWVYZDZ6V3PMY6NHT"
  secret_key="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"
 }

resource "aws_vpc" "terraform_vpc" {
  provider = aws.ap_south
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
 }

resource "aws_subnet" "public_subnet" {
  provider = aws.ap_south
  vpc_id = aws_vpc.terraform_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-2a"
 }

resource "aws_subnet" "private_subnet" {
  provider = aws.ap_south
  vpc_id = aws_vpc.terraform_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-2b"
 }

resource "aws_internet_gateway" "terraform_igw" {
  provider = aws.ap_south
  vpc_id = aws_vpc.terraform_vpc.id
 }

resource "aws_route_table" "terraform_rt" {
  provider = aws.ap_south
  vpc_id = aws_vpc.terraform_vpc.id
 }

resource "aws_route_table_association" "rt_association" {
  provider = aws.ap_south
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.terraform_rt.id
 }

resource "aws_route" "igw_route" {
  provider = aws.ap_south
  route_table_id = aws_route_table.terraform_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.terraform_igw.id
 }

resource "aws_key_pair" "new_key_pair" {
  key_name = "my-new-key-pair"
  public_key = file("my-new-key.pub")
 }

resource "aws_instance" "terraform_instance" {
  provider = aws.ap_south
  ami = "ami-04a5a6be1fa530f1c"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnet.id
  key_name = aws_key_pair.new_key_pair.key_name

  tags = {
   Name = "EC2WithExistingKey"
 }
  
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    
    echo "<html><body><h1>Hello, Terraform!</h1></body></html>" > /var/www/html/index.html
    
    service nginx start
    EOF
}

