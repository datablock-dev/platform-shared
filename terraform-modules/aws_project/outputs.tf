output "staging_account_id" {
  value = aws_organizations_account.this["staging"].id
}

output "production_account_id" {
  value = aws_organizations_account.this["production"].id
}

output "ou_id" {
  value = aws_organizations_organizational_unit.this.id
}
