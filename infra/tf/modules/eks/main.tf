######################################################################
###                  IAM Role For Control Plane
######################################################################

resource "aws_iam_role" "eks-cluster" {
  name = "eks-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazon-ssm-managed-instance" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "amazon-eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster.name
}

######################################################################
###                       EKS Cluster
######################################################################

resource "aws_eks_cluster" "cluster" {
  name     = "my-eks"
  version  = "1.31"
  role_arn = aws_iam_role.eks-cluster.arn

  vpc_config {
    subnet_ids = concat(var.private_subnets, var.public_subnets)
    security_group_ids = [aws_security_group.eks_cluster.id]

  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.amazon-eks-cluster-policy]
}

resource "aws_security_group" "eks_cluster" {
  name        = "eks-cluster-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
###                       Cluster's SG
######################################################################
resource "aws_security_group" "eks_node" {
  name        = "eks-node-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.rds_sg]
  }
}

######################################################################
###              IAM Roles for Node Group (Worker Nodes)
######################################################################


resource "aws_iam_role" "nodes" {
  name = "eks-node-group-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_instance_profile" "node_profile" {
  name = "eks-node-profile"
  role = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "amazon-ssm-managed-instance1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "amazon-eks-worker-node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "amazon-eks-cni-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "amazon-ec2-container-registry-read-only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}
######################################################################
###                     Node Group (Worker Nodes)
######################################################################
resource "aws_key_pair" "eks_key" {
  key_name   = "eks-key"
  public_key = file(var.eks_key_public)
}



  resource "aws_eks_node_group" "private-nodes" {
  cluster_name    = aws_eks_cluster.cluster.name
  version         = "1.31"
  node_group_name = "private-nodes"
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = var.private_subnets
  
  capacity_type  = "ON_DEMAND"
  instance_types = [var.instance_type]

  scaling_config {
    desired_size = 3
    max_size     = 4
    min_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }
  remote_access {
    ec2_ssh_key = aws_key_pair.eks_key.id
    source_security_group_ids = [aws_security_group.eks_node.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon-eks-worker-node-policy,
    aws_iam_role_policy_attachment.amazon-eks-cni-policy,
    aws_iam_role_policy_attachment.amazon-ec2-container-registry-read-only,
    aws_iam_role_policy_attachment.amazon-ssm-managed-instance1,
  ]

  # Allow external changes without Terraform plan difference
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

######################################################################
###                    Load Balancer Controller
######################################################################

data "aws_iam_policy_document" "aws_lbc" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "aws_lbc" {
  name               = "aws-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
}

resource "aws_iam_policy" "aws_lbc" {
  policy = file("/home/keretdodor/Desktop/eks-project/eks-flask-project/infra/tf/modules/eks/aws_lb_controller_iam.json")
  name   = "AWSLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  policy_arn = aws_iam_policy.aws_lbc.arn
  role       = aws_iam_role.aws_lbc.name
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = aws_eks_cluster.cluster.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc.arn
}

resource "kubernetes_service_account" "aws_lbc" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
  }
}

######################################################################
###                    EBS CSI Driver Setup
######################################################################

data "aws_iam_policy_document" "ebs_csi_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "eks-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

resource "kubernetes_service_account" "ebs_csi_controller" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_driver.arn
    }
  }
  depends_on = [aws_eks_node_group.private-nodes]
}

# Add EBS CSI addon to EKS cluster
resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.cluster.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version              = "v1.38.1-eksbuild.1"  # Check latest version in AWS console
  service_account_role_arn   = aws_iam_role.ebs_csi_driver.arn

  depends_on = [
    aws_eks_node_group.private-nodes,
    kubernetes_service_account.ebs_csi_controller
  ]
}

######################################################################
###                    OIDC Provider for EKS
######################################################################

# Get thumbprint for OIDC provider
data "tls_certificate" "eks" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# Create OIDC provider for EKS
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}


######################################################################
###                     Helm and Cluster Addons
######################################################################

resource "aws_eks_addon" "pod_identity" {
  cluster_name                = aws_eks_cluster.cluster.name
  addon_name                  = "eks-pod-identity-agent"
  addon_version              = "v1.3.4-eksbuild.1" 
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.private-nodes]
}

provider "kubernetes" {
  host                   = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.cluster.name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

resource "helm_release" "aws_lbc" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

  timeout = 600

  set {
    name  = "clusterName"
    value = aws_eks_cluster.cluster.name
  }

    set {
    name  = "serviceAccount.create"
    value = "false"  
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "region"
    value = var.region 
  }

  set {
    name  = "vpcId"
    value = var.vpc_id 
  }

 depends_on = [
    aws_eks_node_group.private-nodes,
    aws_eks_pod_identity_association.aws_lbc,
    kubernetes_service_account.aws_lbc,
    aws_eks_addon.pod_identity
  ]
}

resource "helm_release" "argocd" {
  
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "4.5.2"

  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "server.service.port"
    value = "80"  # This is the port the service will listen on
  }

  set {
    name  = "server.service.targetPort"
    value = "8081"  # This is the port your application is listening on
  }

  depends_on = [aws_eks_node_group.private-nodes, helm_release.aws_lbc]
}


######################################################################
###                    Prometheus & Grafana Setup
######################################################################

# Create namespace for monitoring
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }

  depends_on = [aws_eks_node_group.private-nodes]
}

resource "helm_release" "prometheus" {

  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.id
  create_namespace = true
  version    = "67.7.0"

set {
    name  = "podSecurityPolicy.enabled"
    value = true
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = true
  }

  depends_on = [
    kubernetes_namespace.monitoring,
    aws_eks_addon.ebs_csi
  ]
} 

######################################################################
###                   Elasticsearch & Kibana Setup
######################################################################

# resource "kubernetes_namespace" "logging" {
#   metadata {
#     name = "logging"
#   }
# 
#   depends_on = [aws_eks_node_group.private-nodes]
# }
# 
# resource "kubernetes_storage_class" "elasticsearch" {
#   metadata {
#     name = "elasticsearch-storage"
#   }
# 
#   storage_provisioner = "kubernetes.io/aws-ebs"
#   reclaim_policy     = "Retain"
#   parameters = {
#     type = "gp2"
#   }
# }


# resource "helm_release" "elasticsearch" {
#   name       = "elasticsearch"
#   repository = "https://helm.elastic.co"
#   chart      = "elasticsearch"
#   namespace  = kubernetes_namespace.logging.metadata[0].name
#   version    = "8.5.1"  
# 
#   set {
#     name  = "replicas"
#     value = "3"
#   }
# 
#   set {
#     name  = "minimumMasterNodes"
#     value = "2"
#   }
# 
#   set {
#     name  = "volumeClaimTemplate.storageClassName"
#     value = kubernetes_storage_class.elasticsearch.metadata[0].name
#   }
# 
#   set {
#     name  = "volumeClaimTemplate.resources.requests.storage"
#     value = "10Gi"
#   }
#    # Add resource limits
#   set {
#     name  = "resources.requests.cpu"
#     value = "500m"
#   }
# 
#   set {
#     name  = "resources.requests.memory"
#     value = "1Gi"
#   }
# 
#   set {
#     name  = "resources.limits.cpu"
#     value = "1000m"
#   }
# 
#   set {
#     name  = "resources.limits.memory"
#     value = "2Gi"
#   }
# 
#   # Add initialization settings
#   set {
#     name  = "antiAffinity"
#     value = "soft"
#   }
# 
#   depends_on = [kubernetes_namespace.logging, kubernetes_storage_class.elasticsearch]
# }
# 
# 
# resource "helm_release" "kibana" {
#   name       = "kibana"
#   repository = "https://helm.elastic.co"
#   chart      = "kibana"
#   namespace  = kubernetes_namespace.logging.metadata[0].name
#   version    = "8.5.1"  
# 
#   set {
#     name  = "elasticsearchHosts"
#     value = "http://elasticsearch-master:9200"
#   }
# 
#   depends_on = [helm_release.elasticsearch]
# }