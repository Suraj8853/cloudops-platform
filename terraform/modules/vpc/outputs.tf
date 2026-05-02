output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id

}

output "public_subnet_ids" {
  description = "list of subnet public ids"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "list of subnet private ids"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  description = "nat gateway id"
  value       = aws_nat_gateway.main.id
}
