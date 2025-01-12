terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.55"
    }
  }

  required_version = ">= 1.7.0"

  backend "s3" {
    bucket = "eks-bucket-with-respect-us"
    key    = "tfstate.json"
    region = "us-east-1"

  }

}
provider "aws" {
  region = local.region
   default_tags {
    tags = {
      Owner      = "dor.keret" 
      Objective  = "Candidate"
      Name       = "dor.keret"
    }
   }
}

module "network" {
    source        = "./modules/network"
    
    region                = local.region
    instance_type         = local.instance_type
    bastion_key_private   = local.bastion_key_private
    bastion_key_public    = local.bastion_key_public
    eks_key_private       = local.eks_key_private
    eks_node_sg           = module.eks.node_sg
    eks_cluster_sg        = module.eks.cluster_sg
    init_sg               = module.rds.init_sg
}


module "eks" {
    source        = "./modules/eks"

     region                  = local.region
     rds_sg                  = module.rds.rds_sg
     instance_type           = local.instance_type
     private_subnets         = module.network.private_subnets
     public_subnets          = module.network.public_subnets
     bastion_private_ip      = module.network.bastion_private_ip
     vpc_id                  = module.network.vpc_id
     eks_key_private         = local.eks_key_private
     eks_key_public          = local.eks_key_public
   
}


module "rds" {
    source        = "./modules/rds"

    init_runner_private   = local.init_runner_key_private 
    init_runner_public    = local.init_runner_key_public 
    private_subnets       = module.network.private_subnets
    public_subnets        = module.network.public_subnets
    instance_type         = local.instance_type
    db_user               = local.db_user
    db_pass               = local.db_pass
    vpc_id                = module.network.vpc_id
}            