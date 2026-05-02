
output "github_action_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
value = aws_iam_role.github_actions.arn
}

output "github_action_role_name" {
  description = "name of the github actions role"
  value = aws_iam_role.github_actions.name
}

output "oidc_provider_arn" {
    description = "arn of the oidc provider"
    value = aws_iam_openid_connect_provider.github.arn
  
}