resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "eks.amazonaws.com"
            }
        }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role = aws_iam_role.eks_cluster.name
  
}

resource "aws_security_group" "eks_cluster" {
    name = "${var.cluster_name}-cluster-sg"
    description = "security group for eks"
    vpc_id = var.vpc_id
    egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
      Name = "${var.cluster_name}-cluster-sg"
      Environment = var.environment
    }
  
}

resource "aws_eks_cluster" "main" {
name = "${var.cluster_name}"
version = var.cluster_version
role_arn = aws_iam_role.eks_cluster.arn
vpc_config {
  subnet_ids = concat(var.public_subnet_ids,var.private_subnet_ids)
  security_group_ids = [aws_security_group.eks_cluster.id]
  endpoint_public_access = true 
  endpoint_private_access = true

}
depends_on = [ aws_iam_role_policy_attachment.eks_cluster_role_policy ]
tags = {
    Name = var.cluster_name
    Environment = var.environment
}

  
}

resource "aws_iam_role" "eks_nodes" {
name = "${var.cluster_name}-node-role"
assume_role_policy = jsonencode({
Version = "2012-10-17"
Statement = [{
    Action = "sts:AssumeRole"
    Effect = "Allow"
    Principal = {
        Service = "ec2.amazonaws.com"
    }
}]
})  
tags = {
    Environment = var.environment
}
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role = aws_iam_role.eks_nodes.name

}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.eks_nodes.name
}

resource "aws_eks_node_group" "main" {
    cluster_name = aws_eks_cluster.main.name
    node_role_arn = aws_iam_role.eks_nodes.arn
    subnet_ids = var.private_subnet_ids
    scaling_config {
      desired_size = var.node_desired_size
      min_size = var.node_min_size
      max_size = var.node_max_size
    }
    update_config {
      max_unavailable = 1
    }
    depends_on = [ 
        aws_iam_role_policy_attachment.eks_worker_node_policy,
        aws_iam_role_policy_attachment.eks_cni_policy,
        aws_iam_role_policy_attachment.eks_ecr_policy
     ]
     tags = {
        Name = "${var.cluster_name}-node-group"
        Environment = "${var.environment}"
     }
  
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer

}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list = ["sts.amazonaws.com"]
   url = aws_eks_cluster.main.identity[0].oidc[0].issuer
   thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
   tags = {
    Name = "${var.cluster_name}-oidc-provider"
    Environment = var.environment
   }
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name = "coredns"
  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name = "kube-proxy"
}

resource "aws_eks_addon" "vpc_cni" {
   cluster_name = aws_eks_cluster.main.name
   addon_name = "vpc-cni"
}

/* resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.main.name
  addon_name = "aws-ebs-csi-driver"
    depends_on = [aws_eks_node_group.main]
} */

# IRSA Role for EBS CSI Driver
data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${var.cluster_name}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}

# Add EBS CSI addon with service account role
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi
  ]
}



