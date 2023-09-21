### Module Main

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.vpc_name}-vpc"
    Environment = "educatif"
    Owner = "bilal.scouri@gmail.com"
    Terraform = "true"
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id = aws_vpc.vpc.id
  for_each = var.azs
  cidr_block = cidrsubnet(var.vpc_cidr_block, 4, each.value)
  availability_zone = "${var.aws_region}${each.key}"

  tags = {
    Name = "${var.vpc_name}-public-${var.aws_region}${each.key}"
  }
}

resource "aws_subnet" "subnet_private" {
  vpc_id = aws_vpc.vpc.id
  for_each = var.azs
  cidr_block = cidrsubnet(var.vpc_cidr_block, 4, 15-each.value)
  availability_zone = "${var.aws_region}${each.key}"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.vpc_name}-private-${var.aws_region}${each.key}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-gw"
  }
}

data "aws_ami" "amazon-ami" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-2018.03.0.2021*"]
  }
}

resource "aws_security_group" "sg" {
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_name}-sg"
  }
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr_block]
  security_group_id = "${aws_security_group.sg.id}"
}

resource "aws_security_group_rule" "ssh-ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.sg.id}"
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.sg.id}"
}

resource "aws_key_pair" "aws-key" {
  key_name   = "aws-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8pmmWkn6kUz7TyL0ypxCbBxESpX8WhrZrNnlbJGEN4 bilalscouri@FRLA000418"
}

resource "aws_instance" "nat-instance" {
  for_each = var.azs
  ami           = data.aws_ami.amazon-ami.id
  instance_type = "t2.micro"
  source_dest_check = false

  tags = {
    Name = "${var.vpc_name}-nat-${var.aws_region}${each.key}"
  }
}