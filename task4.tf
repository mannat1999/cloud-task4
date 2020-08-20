
resource "aws_vpc" "vpc-4" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-4"
  }
}


resource "aws_subnet" "task4subnet1" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.0.0/24"
  map_public_ip_on_launch = "true"
  availability_zone="ap-south-1a"
  tags = {
    Name = "task4subnet1"
  }
}

resource "aws_subnet" "task4subnet2" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone="ap-south-1b"
  tags = {
    Name = "task4subnet2"
  }
}

resource "aws_internet_gateway" "task4igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "task4igw"
  }
}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.task4igw.id}"
  }
 tags = {
    Name = "task4rt"
  }
}


resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.task4subnet1.id
  route_table_id = aws_route_table.r.id
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "task4pubsg" {
  name        = "task4pubsg"
  description = "Allow public to connect wp"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
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
    Name = "task4pubsg"
  }
}


resource "aws_security_group" "tassk4prisg" {
  name        = "task4prisg"
  description = "Allow wp to connect mysql"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
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
    Name = "task4prisg"
  }
}


resource "aws_security_group" "my_bastion" {
  name        = "task4bastion"
  description = "Allow ssh for bastion host"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "for ssh"
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
    Name = "task4bastion"
  }
}


resource "aws_security_group" "ssh_allow" {
  name        = "ssh_allow"
  description = "ssh from mysql"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "for ssh"
    security_groups =[ "${aws_security_group.task4bastion.id}" ]
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
    Name = "ssh_allow"
  }
}


resource "aws_instance" "task4_wordpress" {
ami = "ami-000cbce3e1b899ebd"
instance_type = "t2.micro"
key_name = "mykey1111"
subnet_id = "${aws_subnet.task4subnet1.id}"
security_groups = ["${aws_security_group.wp_sg.id}"]

tags = {
   Name = "task4-wordpress"
  }
}


resource "aws_instance" "task4_mysql" {
ami = "ami-08706cb5f68222d09"
instance_type = "t2.micro"
key_name = "mykey1111"
subnet_id = "${aws_subnet.subnet2.id}"
security_groups = ["${aws_security_group.mysql_sg.id}","${aws_security_group.mysql_allow.id}"]

tags = {
   Name  = "task4-mysql"
  }
}


resource "aws_instance" "task4_bastion" {
ami = "ami-0732b62d310b80e97"
instance_type = "t2.micro"
key_name = "mykey1111"
availability_zone = "ap-south-1a"
subnet_id = "${aws_subnet.task4subnet1.id}"
security_groups = [ "${aws_security_group.my_bastion.id}" ]

tags = {
Name = "task4-bastion"
    }
}


resource "aws_eip" "task4_eip" {
vpc = true
depends_on = ["aws_internet_gateway.myigw"]

tags = {
Name = "task4-eip"
    }
}


resource "aws_nat_gateway" "task4_nat_gateway" {
  allocation_id = "${aws_eip.my_eip.id}"
  subnet_id     = "${aws_subnet.subnet1.id}"

  tags = {
    Name = "task4-nat-gateway"
  }
}

resource "aws_route_table" "r2" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.task4_nat_gateway.id}"
  }
    tags = {
    Name = "task4nat-r2"
  }
}



resource "aws_route_table_association" "b" {
subnet_id      = aws_subnet.task4subnet2.id
route_table_id = "${aws_route_table.r2.id}"
}
