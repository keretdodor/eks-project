variable "instance_type" {
   description = "Instance Type"
   type        = string
}

variable "private_subnets" {
  type        = list
  description = "List of subnets from the VPC module"
}

variable "public_subnets" {
  type        = list
  description = "List of subnets from the VPC module"
}

variable "vpc_id" {
  type        = string
  description = "The vpc id"
}

variable "bastion_private_ip" {
  type        = string
  description = "private bastion ip"
}

variable "eks_key_private" {
  type        = string
  description = "The full alias record"
}

variable "eks_key_public" {
  type        = string
  description = "The full alias record"
}

variable "rds_sg" {
  type        = string
  description = "The full alias record"
}

variable "region" {
  type        = string
  description = "The full alias record"
}

variable "aws_lbc_path" {
  description = "Path to AWS Load Balancer Controller IAM policy"
  type        = string
}