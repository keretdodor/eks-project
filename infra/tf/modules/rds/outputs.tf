output "init_sg" {
  value = aws_security_group.init_sg.id
}


output "rds_sg" {
  value = aws_security_group.rds_sg.id
}
