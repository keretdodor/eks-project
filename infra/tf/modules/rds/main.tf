######################################################################
###                            S3 Bucket Creation
######################################################################

resource "aws_s3_bucket" "init_bucket" {
  bucket = "your-init-sql-bucket-2"
}

resource "aws_s3_object" "init_sql" {
  bucket = aws_s3_bucket.init_bucket.id
  key    = "init.sql"
  source = "/home/keretdodor/Desktop/eks-project/eks-flask-project/docker-compose/mysql/init.sql"
  acl    = "private"
}
######################################################################
###                            RDS Instance 
######################################################################
resource "aws_db_subnet_group" "rds" {
  name       = "my-db-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "My DB Subnet Group"
  }
}

resource "aws_db_instance" "rds" {
   allocated_storage      = 20
   storage_type           = "gp2"
   identifier             = "mydb"
   engine                 = "mysql"
   engine_version         = "8.0.39"
   instance_class         = "db.t3.micro"
   username               = var.db_user
   password               = var.db_pass
   publicly_accessible    = true
   skip_final_snapshot    = true
   vpc_security_group_ids = [aws_security_group.rds_sg.id] 
   db_subnet_group_name   = aws_db_subnet_group.rds.name
   backup_retention_period = 7
}

resource "aws_db_instance" "rds_replica" {
  instance_class         = "db.t3.micro"
  identifier            = "mydb-replica"
  replicate_source_db   = aws_db_instance.rds.arn
  publicly_accessible   = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name  = aws_db_subnet_group.rds.name
  backup_retention_period = 7
  skip_final_snapshot   = true

  depends_on = [aws_db_instance.rds]
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id  

  ingress {
    from_port   = 3306   
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"]  
  }

}
######################################################################
###                        Temporary init instance
######################################################################
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}

resource "aws_instance" "init_runner" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.init.key_name
  subnet_id     = var.public_subnets[1]
  vpc_security_group_ids   = [aws_security_group.init_sg.id]

  depends_on = [aws_db_instance.rds]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

     provisioner "file" {
    source      = "/home/keretdodor/Desktop/eks-project/eks-flask-project/infra/tf/modules/rds/rds-init.sh"
    destination = "/tmp/rds-init.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.init_runner_private)
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.init_runner_private)
      host        = self.public_ip
    }

    inline = [
      "chmod +x /tmp/rds-init.sh",
      "DB_ENDPOINT=\"${split(":", aws_db_instance.rds.endpoint)[0]}\"", 
      "/tmp/rds-init.sh \"${aws_s3_bucket.init_bucket.id}\" \"$DB_ENDPOINT\" \"${aws_db_instance.rds.username}\" \"${aws_db_instance.rds.password}\""
    ]
  }
}
resource "aws_key_pair" "init" {
  key_name   = "init-key"
  public_key = file(var.init_runner_public) 
}

resource "aws_security_group" "init_sg" {
  name        = "init-security-group"
  description = "Security group open to all traffic from everywhere"
  vpc_id      = var.vpc_id 


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

######################################################################
###                        IAM Role for S3 Access
######################################################################

resource "aws_iam_role" "ec2_role" {
  name               = "ec2-s3-access-role"
  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          }
        }
      ]
    }
  EOF
}

resource "aws_iam_policy" "s3_access_policy" {
  name   = "s3-access-policy"
  policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": ["s3:GetObject"],
          "Effect": "Allow",
          "Resource": "arn:aws:s3:::${aws_s3_bucket.init_bucket.id}/*"
        }
      ]
    }
  EOF
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}
