output "repository_urls" {
    description = "URLs of the ECR repositories"
    value = {
        for repo,ecr in aws_ecr_repository.main:
        repo => ecr.repository_url
    }
  
}

output "repository_arn" {
   description = "ARNs of the ECR repositories"
   value = {
    for repo,ecr in aws_ecr_repository.main:
    repo => ecr.arn
   }
}