
output "cluster_name" {
  value = aws_eks_cluster.cluster.id
}

output "node_sg" {
  value = aws_security_group.eks_node.id
}

output "cluster_sg" {
  value = aws_security_group.eks_cluster.id
}