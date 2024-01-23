output "encrypted_password_data" {
  value = aws_instance.jumpbox.password_data
  sensitive = true
}
