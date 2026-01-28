#-------------------------------------
# Networking Outputs - needed for bootstrap layer
#------------------------------------
output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = module.networking["core"].subnet_ids["private"]
}

# -------------------------------------
# DNS Outputs - needed for bootstrap layer
# ------------------------------------
output "private_dns_zone_blob_id" {
  description = "The ID of the private DNS zone for blob"
  value       = module.dns["blob"].private_dns_zone_id
}
