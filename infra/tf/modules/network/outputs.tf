output "private_subnets" {
  value       = [aws_subnet.eks_private_subnet-1.id, aws_subnet.eks_private_subnet-2.id]
  description = "List of private subnet IDs"
}

output "public_subnets" {
  value       = [aws_subnet.eks_public_subnet-1.id, aws_subnet.eks_public_subnet-2.id]
  description = "List of private subnet IDs"
}

output "vpc_id" {
  value = aws_vpc.eks_vpc.id
  description = "The vpc's id"
}

output "bastion_private_ip" {
  value = aws_instance.eks_bastion.private_ip
  description = "The private IP address of the bastion host"
}

output "bastion_public_ip" {
  value = aws_instance.eks_bastion.public_ip
  description = "The private IP address of the bastion host"
}

output "nat_gateway_id" {
  value = aws_nat_gateway.eks_nat.id
}
