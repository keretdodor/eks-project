######################################################################
###                            VPC Creation
######################################################################
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
  }
}
######################################################################
###                          Internet Gateway
######################################################################
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "eks-igw"
  }
}

######################################################################
###                     Private and Public Subnets
######################################################################

resource "aws_subnet" "eks_public_subnet-1" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.0.0/19"
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available_azs.names[0]
   tags = {
    "Name"                                      = "eks-public-subnet"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/my-eks" = "owned"
  }
}

resource "aws_subnet" "eks_public_subnet-2" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.32.0/19"
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available_azs.names[1]
  
    tags = {
    "Name"                                      = "eks-public-subnet"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/my-eks" = "owned"
  }
  }


resource "aws_subnet" "eks_private_subnet-1" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.64.0/19"
  availability_zone = data.aws_availability_zones.available_azs.names[0]
  tags = {
    Name = "eks-private-subnet-1"
  }
}
resource "aws_subnet" "eks_private_subnet-2" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.96.0/19"
  availability_zone = data.aws_availability_zones.available_azs.names[1]
  tags = {
    Name = "eks-private-subnet-2"
  }
}

######################################################################
###                          SSM Endpoints
######################################################################

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.eks_vpc.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.eks_private_subnet-1.id, aws_subnet.eks_private_subnet-2.id]
  security_group_ids  = [var.eks_node_sg, var.eks_cluster_sg, var.init_sg]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.eks_vpc.id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.eks_private_subnet-1.id, aws_subnet.eks_private_subnet-2.id]
  security_group_ids  = [var.eks_node_sg, var.eks_cluster_sg, var.init_sg]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.eks_vpc.id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.eks_private_subnet-1.id, aws_subnet.eks_private_subnet-2.id]
  security_group_ids  = [var.eks_node_sg, var.eks_cluster_sg, var.init_sg]
  private_dns_enabled = true
}


######################################################################
###                             NACLs
######################################################################


# resource "aws_network_acl" "eks_public_nacl" {
#   vpc_id = aws_vpc.eks_vpc.id
# 
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 22
#     to_port    = 22
#   }
# 
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 200
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 443
#     to_port    = 443
#   }
# 
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 300
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 1024
#     to_port    = 65535
#   }
# 
#   egress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }
# 
#   subnet_ids = [
#     aws_subnet.eks_public_subnet-1.id,
#     aws_subnet.eks_public_subnet-2.id
#   ]
# 
#   tags = {
#     Name = "eks-public-nacl"
#   }
# }
# 
# resource "aws_network_acl" "eks_private_nacl" {
#   vpc_id = aws_vpc.eks_vpc.id
#   
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "${aws_instance.eks_bastion.private_ip}/32"
#     from_port  = 22
#     to_port    = 22
#   }
# 
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 200
#     action     = "allow"
#     cidr_block = "10.0.0.0/16"  # VPC CIDR
#     from_port  = 80
#     to_port    = 80
#   }
# 
#   ingress {
#     protocol   = "tcp"
#     rule_no    = 300
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 1024
#     to_port    = 65535
#   }
# 
#   egress {
#     protocol   = "-1"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     to_port    = 0
#   }
# 
#   subnet_ids = [
#     aws_subnet.eks_private_subnet-1.id,
#     aws_subnet.eks_private_subnet-2.id
#   ]
# 
#   tags = {
#     Name = "eks-private-nacl"
#   }
# }


######################################################################
###                    Nat Gateway and Elastic IP
######################################################################
resource "aws_nat_gateway" "eks_nat" {
  allocation_id = aws_eip.eks_nat.id
  subnet_id     = aws_subnet.eks_public_subnet-1.id
  tags = {
    Name = "eks-nat-gateway"
  }
}

resource "aws_eip" "eks_nat" {
  tags = {
    Name = "eks-nat-eip"
  }
}

######################################################################
###                  Private and Public Route Tables
######################################################################

resource "aws_route_table" "eks_public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "eks-public-route-table"
  }
}

resource "aws_route" "eks_public_route" {
  route_table_id         = aws_route_table.eks_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_igw.id
}

resource "aws_route_table_association" "eks_public-1" {
  subnet_id      = aws_subnet.eks_public_subnet-1.id
  route_table_id = aws_route_table.eks_public_route_table.id
}

resource "aws_route_table_association" "eks_public-2" {
  subnet_id      = aws_subnet.eks_public_subnet-2.id
  route_table_id = aws_route_table.eks_public_route_table.id
}

resource "aws_route_table" "eks_private_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "eks-private-route-table"
  }
}

resource "aws_route" "eks_private_route" {
  route_table_id         = aws_route_table.eks_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.eks_nat.id
}

resource "aws_route_table_association" "eks_private-1" {
  subnet_id      = aws_subnet.eks_private_subnet-1.id
  route_table_id = aws_route_table.eks_private_route_table.id
}

resource "aws_route_table_association" "eks_private-2" {
  subnet_id      = aws_subnet.eks_private_subnet-2.id
  route_table_id = aws_route_table.eks_private_route_table.id
}

######################################################################
###                         Bastion Host
######################################################################

resource "aws_instance" "eks_bastion" {
  ami                      = data.aws_ami.ubuntu_ami.id
  instance_type            = var.instance_type
  key_name                 = aws_key_pair.bastion_key.key_name
  subnet_id                = aws_subnet.eks_public_subnet-1.id
  vpc_security_group_ids   = [aws_security_group.eks_bastion_sg.id]
  tags = {
    Name = "eks-bastion-host"
  }

}

resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion-key"
  public_key = file(var.bastion_key_public) # Path to your public key
}

resource "aws_security_group" "eks_bastion_sg" {
  name        = "bastion-sg"  
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.eks_vpc.id

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
  

}