variable "sentry_organization" {
  description = "Slug of the Sentry organization (e.g. 'datablock')"
  type        = string
}

variable "sentry_team_slug" {
  description = "Slug of the Sentry team to assign this project to"
  type        = string
}

variable "sentry_project_name" {
  description = "Display name of the Sentry project (e.g. 'Platform Frontend')"
  type        = string
}

variable "sentry_project_slug" {
  description = "URL slug for the Sentry project (e.g. 'platform-frontend')"
  type        = string
}

variable "sentry_platform" {
  description = "Sentry platform identifier (e.g. 'javascript-nextjs', 'node')"
  type        = string
}
