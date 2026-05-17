resource "aws_iam_openid_connect_provider" "github" {
  url             =  "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags = {
    Name        = "${var.project_name}-${var.environment}-oidc-github"
    Environment = "${var.environment}"
    Project     = "${var.project_name}"
  }
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }

      }


    ]
  })

}

resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions-policy"
  role = aws_iam_role.github_actions.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"


        ]
        Resource = "*"

      }

    ]

  })
}

resource "aws_iam_role_policy" "secrets_manager_access" {
  name = "${var.project_name}-${var.environment}-secrets-manager-policy"
  role = var.node_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:cloudops/*"
      }
    ]
  })
}



resource "aws_iam_role" "external_secrets" {
  name = "${var.project_name}-${var.environment}-external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/oidc.eks.ap-south-1.amazonaws.com/id/${var.oidc_id}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "oidc.eks.ap-south-1.amazonaws.com/id/${var.oidc_id}:sub" = "system:serviceaccount:external-secrets:external-secrets"
            "oidc.eks.ap-south-1.amazonaws.com/id/${var.oidc_id}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "external_secrets" {
  name = "${var.project_name}-${var.environment}-external-secrets-policy"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:ap-south-1:${var.aws_account_id}:secret:cloudops/*"
      }
    ]
  })
}
