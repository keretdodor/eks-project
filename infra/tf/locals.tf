locals {
  region                       = "us-east-1"
  instance_type                = "t3a.medium"
  bastion_key_private          = "/home/keretdodor/Desktop/eks-project/extras/bastion-key-develeap.pem"
  bastion_key_public           = "/home/keretdodor/Desktop/eks-project/extras/bastion-key-develeap.pub"
  eks_key_private              = "/home/keretdodor/Desktop/eks-project/extras/eks.pem"
  eks_key_public               = "/home/keretdodor/Desktop/eks-project/extras/eks.pub"
  init_runner_key_private      = "/home/keretdodor/Desktop/eks-project/extras/init_runner_key.pem"
  init_runner_key_public       = "/home/keretdodor/Desktop/eks-project/extras/init_runner_key.pub"
  db_user                      = 
  db_pass                      =
  aws_lbc     = "/home/keretdodor/Desktop/eks-project/eks-flask-project/infra/tf/modules/eks/aws_lb_controller_iam.json"
  init_script = "/home/keretdodor/Desktop/eks-project/eks-flask-project/infra/tf/modules/rds/rds-init.sh"

}

