output "vpc_id" {
  value = aws_vpc.main_infra.id
}

output "frontend_subnet_id" {
  value = aws_subnet.frontend_subnet_1.id
}

output "frontend_subnet_2_id" {
  value = aws_subnet.frontend_subnet_2.id
}

output "backend_subnet_id" {
  value = aws_subnet.backend_subnet_1.id
}

output "backend_subnet_2_id" {
  value = aws_subnet.backend_subnet_2.id
}