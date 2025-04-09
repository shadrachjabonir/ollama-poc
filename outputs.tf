output "spot_instance_id" {
  description = "ID dari Spot Instance yang dibuat"
  value       = aws_spot_instance_request.ollama_spot.spot_instance_id
}

output "spot_instance_public_ip" {
  description = "Public IP dari Spot Instance (setelah fulfilled)"
  value       = aws_spot_instance_request.ollama_spot.public_ip
}
