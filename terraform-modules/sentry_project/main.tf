resource "sentry_project" "this" {
  organization = var.sentry_organization
  teams        = [var.sentry_team_slug]
  name         = var.sentry_project_name
  slug         = var.sentry_project_slug
  platform     = var.sentry_platform
}

data "sentry_key" "this" {
  organization = var.sentry_organization
  project      = sentry_project.this.slug
  first        = true
}
