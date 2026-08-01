# Without this the github data source below would resolve to hashicorp/github:
# Terraform defaults an undeclared provider in a child module to the hashicorp
# namespace rather than inheriting the root module's source address.
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    github = {
      source = "integrations/github"
    }
  }
}
