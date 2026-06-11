output "dsn_public" {
  description = "Public DSN for this Sentry project"
  value       = data.sentry_key.this.dsn["public"]
}
