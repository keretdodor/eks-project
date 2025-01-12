variable "instance_type" {
   description = "Instance Type"
   type        = string
}

variable "bastion_key_public" {
  type        = string
  description = "The full alias record"
}

variable "bastion_key_private" {
  type        = string
  description = "The full alias record"
}

variable "eks_key_private" {
  type        = string
  description = "The full alias record"
}

variable "eks_node_sg" {
  type        = string
  description = "The full alias record"
}

variable "eks_cluster_sg" {
  type        = string
  description = "The full alias record"
}

variable "init_sg" {
  type        = string
  description = "The full alias record"
}

variable "region" {
  type        = string
  description = "The full alias record"
}