provider "aws" {
    region = "us-east-1"
}

# VPC creation
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
}

# Subnet creation
resource "aws_subnet" "subnet-public-1" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1a"
}

# Create an internet gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.vpc.id}"
}

# Create a custom route table for public subnets
resource "aws_route_table" "public-crt" {
    vpc_id = "${aws_vpc.vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }
}

# Route table association for the public subnets
resource "aws_route_table_association" "crta-public-subnet-1" {
    subnet_id = "${aws_subnet.subnet-public-1.id}"
    route_table_id = "${aws_route_table.public-crt.id}"
}

# Create security group
resource "aws_security_group" "allow-ssh-http" {

    vpc_id = "${aws_vpc.vpc.id}"

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        
        // Temp!! All ip address are allowed to ssh !
        // Need to provide whitelisted IP range here for production
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Create load balancer
resource "aws_elb" "web-elb" {
  subnets         = ["${aws_subnet.subnet-public-1.id}"]
  security_groups = ["${aws_security_group.allow-ssh-http.id}"]
  instances       = ["${aws_instance.web.id}"]

  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

}

# Create launch configuration
resource "aws_launch_configuration" "web-lc" {
  name_prefix = "web-"
  image_id = "${var.AMI}"
  instance_type = "t2.micro"
  # Security group
  security_groups = ["${aws_security_group.allow-ssh-http.id}"]
  user_data = "${file("userdata.sh")}"
  key_name = "${var.PRIVATE_KEY_PATH}"
}

# Create auto scaling group
resource "aws_autoscaling_group" "webserver-asg" {
  availability_zones = ["us-east-1a"]
  max_size = 1
  min_size = 1
  desired_capacity = 1
  force_delete = true
  launch_configuration = "${aws_launch_configuration.web-lc.id}"
  load_balancers = ["${aws_elb.web-elb.id}"]
}

resource "aws_key_pair" "auth" {
  key_name = "rsa"
  public_key = "${file(var.PUBLIC_KEY_PATH)}"
}

resource "aws_instance" "web" {

    ami = "${var.AMI}"
    instance_type = "t2.micro"

    # VPC
    subnet_id = "${aws_subnet.subnet-public-1.id}"

    # Security Group
    vpc_security_group_ids = ["${aws_security_group.allow-ssh-http.id}"]

    # the Public SSH key
    key_name = "${aws_key_pair.auth.id}"

    # nginx installation
    provisioner "file" {
        source = "nginx.sh"
        destination = "/tmp/nginx.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/nginx.sh",
            "sudo /tmp/nginx.sh"
        ]
    }

    connection {
        host = "3.19.158.104"
        user = "${var.EC2_USER}"
        type = "ssh"
        private_key = "${file("${var.PRIVATE_KEY_PATH}")}"
    }
}
