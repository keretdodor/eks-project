variable "db_user" {
   description = "Instance Type"
   type        = string
}

variable "db_pass" {
   description = "Instance Type"
   type        = string
}

variable "instance_type" {
   description = "Instance Type"
   type        = string
}

variable "vpc_id" {
  type        = string
  description = "The vpc id"
}

variable "public_subnets" {
  type        = list
  description = "List of subnets from the VPC module"
}

variable "private_subnets" {
  type        = list
  description = "List of subnets from the VPC module"
}

variable "init_runner_public" {
  type        = string
  description = "init_runner"
}

variable "init_runner_private" {
  type        = string
  description = "init_runner"
}
