locals {
  region                       = "us-east-1"
  instance_type                = "t3a.medium"
  bastion_key_private          = "/home/keretdodor/Desktop/eks-project/extras/bastion-key-develeap.pem"
  bastion_key_public           = "/home/keretdodor/Desktop/eks-project/extras/bastion-key-develeap.pub"
  eks_key_private              = "/home/keretdodor/Desktop/eks-project/extras/eks.pem"
  eks_key_public               = "/home/keretdodor/Desktop/eks-project/extras/eks.pub"
  init_runner_key_private      = "/home/keretdodor/Desktop/eks-project/extras/init_runner_key.pem"
  init_runner_key_public       = "/home/keretdodor/Desktop/eks-project/extras/init_runner_key.pub"
  db_user                      = "admin"
  db_pass                      = "adminadmin"
}

