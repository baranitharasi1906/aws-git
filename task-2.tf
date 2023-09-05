provider "aws" {
 alias = "ap_south"
 region = "us-east-2"
 access_key="AKIAWVYZDZ6V3PMY6NHT"
 secret_key="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"
}

resource "aws_vpc" "vpc_one" {
 provider = aws.ap_south
 cidr_block = "10.0.0.0/16"
 enable_dns_support = true
 enable_dns_hostnames = true
}

resource "aws_subnet" "subnet_one" {
 provider = aws.ap_south
 vpc_id = aws_vpc.vpc_one.id
 cidr_block = "10.0.1.0/24"
 map_public_ip_on_launch = true
 availability_zone = "us-east-2a"
}
 
resource "aws_subnet" "subnet_two" {
 provider = aws.ap_south 
 vpc_id = aws_vpc.vpc_one.id
 cidr_block = "10.0.2.0/24"
 availability_zone = "us-east-2b"
}

resource "aws_route_table" "rt_one" {
 provider = aws.ap_south 
 vpc_id = aws_vpc.vpc_one.id
}

resource "aws_internet_gateway" "igw_one" {
 provider = aws.ap_south
 vpc_id = aws_vpc.vpc_one.id
}
 
resource "aws_route_table_association" "rt_association_one" {
 provider = aws.ap_south
 subnet_id = aws_subnet.subnet_one.id
 route_table_id = aws_route_table.rt_one.id
}
 
resource "aws_route" "rt_igw_one" {
 provider = aws.ap_south
 route_table_id = aws_route_table.rt_one.id
 destination_cidr_block = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.igw_one.id
}

resource "aws_key_pair" "terraform_key" {
  key_name = "tf-key"
  public_key = file("tf-key.pub")
}
 
resource "aws_instance" "instance_01" {
 provider = aws.ap_south
 ami = "ami-024e6efaf93d85776"
 instance_type = "t2.micro"
 subnet_id = aws_subnet.subnet_one.id
 key_name = aws_key_pair.terraform_key.key_name
 
  tags = {
   Name = "lb-instance01"
 }
  
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    
    echo "<html><body><h1>Machine-01!</h1></body></html>" > /var/www/html/index.html
    
    service nginx start
    EOF
}
 
resource "aws_instance" "instance_02" {
 provider = aws.ap_south
 ami = "ami-024e6efaf93d85776"
 instance_type = "t2.micro"
 subnet_id = aws_subnet.subnet_one.id
 key_name = aws_key_pair.terraform_key.key_name

  tags = {
   Name = "lb-instance02"
 }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx

    echo "<html><body><h1>Machine-02!</h1></body></html>" > /var/www/html/index.html

    service nginx start
    EOF
}

resource "aws_instance" "instance_03" {
 provider = aws.ap_south
 ami = "ami-024e6efaf93d85776"
 instance_type = "t2.micro"
 subnet_id = aws_subnet.subnet_one.id
 key_name = aws_key_pair.terraform_key.key_name

  tags = {
   Name = "lb-instance03"
 }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx

    echo "<html><body><h1>Machine-03!</h1></body></html>" > /var/www/html/index.html

    service nginx start
    EOF
}

resource "aws_lb" "lb_one" {
  name               = "lb-one"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-04dfa5110f8a0eae2", "subnet-0674400e11242be92"] 
}

resource "aws_lb_target_group" "lb_tg_one" {
  name     = "lb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_one.id
}

resource "aws_lb_listener" "lb_listener_one" {
  load_balancer_arn = aws_lb.lb_one.arn
  port              = 80
  protocol          = "HTTP"
  
 default_action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.lb_tg_one.arn
  }
}


