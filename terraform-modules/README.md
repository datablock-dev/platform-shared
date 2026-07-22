# terraform-modules

Shared Terraform modules for the `datablock-dev` GitHub organization. Each directory is a standalone module that can be referenced directly from any repo in the org using the GitHub source syntax.

## Using a module

Reference any module by pointing to this repository with a `git` source. Pin to a specific commit SHA for stability, or use a branch/tag.

```hcl
module "my_bucket" {
  source = "github.com/datablock-dev/.github//terraform-modules/aws_bucket_private?ref=main"

  bucket_name = "my-app-assets"
}
```

> **Note:** The double slash `//` separates the repository from the subdirectory path. This is required by Terraform.

Run `terraform init` after adding or changing a module source — Terraform will download the module from GitHub.

### Authentication

Terraform fetches modules over SSH or HTTPS. Make sure the machine (or CI runner) has access to the `datablock-dev` org:

- **Local dev:** SSH key with access to the org, or a `GITHUB_TOKEN` exported in the environment.
- **GitHub Actions:** Use the built-in `GITHUB_TOKEN` or an org-level deploy key. Set `GIT_TERMINAL_PROMPT=0` to prevent hangs.

---

## Available modules

### `aws_bucket_private`

Private S3 bucket with an IAM user and policy for scoped access.

```hcl
module "bucket" {
  source = "github.com/datablock-dev/.github//terraform-modules/aws_bucket_private?ref=main"

  bucket_name  = "my-private-bucket"   # required — used as a name prefix
}
```

| Variable | Type | Default | Description |
|---|---|---|---|
| `bucket_name` | `string` | — | Name prefix for the S3 bucket |
| `bucket_force_destroy` | `bool` | `true` | Delete all objects when the bucket is destroyed |
| `iam_policy_name` | `string` | `"policy-access"` | Name for the IAM policy |
| `iam_policy_statements` | `list(object)` | `null` | Additional bucket policy statements |

**Outputs:** `bucket_id`, `bucket_arn`, `bucket_regional_domain_name`, `iam_user_name`, `iam_user_arn`, `iam_policy_arn`, `iam_policy_id`

---

### `aws_bucket_public_with_cdn`

Public S3 bucket fronted by a CloudFront distribution, with CORS support and an IAM access user.

```hcl
module "cdn_bucket" {
  source = "github.com/datablock-dev/.github//terraform-modules/aws_bucket_public_with_cdn?ref=main"

  bucket_name          = "my-public-assets"   # required
  cors_allowed_origins = ["https://app.example.com"]  # required
}
```

| Variable | Type | Default | Description |
|---|---|---|---|
| `bucket_name` | `string` | — | Name prefix for the S3 bucket |
| `cors_allowed_origins` | `list(string)` | — | Allowed CORS origins |
| `cors_allowed_methods` | `list(string)` | `["GET","PUT","POST","HEAD"]` | Allowed CORS methods |
| `cors_allowed_headers` | `list(string)` | `["*"]` | Allowed CORS headers |
| `cors_expose_headers` | `list(string)` | `["ETag","Content-Length"]` | Exposed CORS headers |
| `cors_max_age_seconds` | `number` | `600` | CORS preflight cache duration |
| `iam_policy_name` | `string` | `"policy-access"` | Name for the IAM policy |

**Outputs:** `bucket_id`, `bucket_arn`, `bucket_regional_domain_name`, `cloudfront_distribution_id`, `cloudfront_distribution_arn`, `cloudfront_domain_name`, `cloudfront_hosted_zone_id`, `cloudfront_oac_id`, `iam_user_name`, `iam_user_arn`, `iam_policy_arn`, `iam_policy_id`

---

### `aws_ecr`

ECR container registry repository.

```hcl
module "ecr" {
  source = "github.com/datablock-dev/.github//terraform-modules/aws_ecr?ref=main"

  name = "my-service"   # required
}
```

| Variable | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Name of the ECR repository |
| `mutability` | `string` | `"MUTABLE"` | Image tag mutability (`MUTABLE` or `IMMUTABLE`) |
| `tags` | `map(string)` | `{}` | Tags to apply to the repository |

**Outputs:** `repository_url`, `repository_name`, `repository_arn`

---

### `aws_iam`

IAM user with a custom policy, optional access key, and optional automatic push of credentials to GitHub Actions secrets.

```hcl
module "iam_user" {
  source = "github.com/datablock-dev/.github//terraform-modules/aws_iam?ref=main"

  iam_name = "my-service-user"   # required
  iam_policy_statements = [      # required
    {
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = ["arn:aws:s3:::my-bucket/*"]
    }
  ]
}
```

| Variable | Type | Default | Description |
|---|---|---|---|
| `iam_name` | `string` | — | IAM username |
| `iam_policy_name` | `string` | `"policy"` | Policy name |
| `iam_policy_statements` | `list(object)` | — | Policy statements (Effect/Action/Resource) |
| `iam_policy_path` | `string` | `"/"` | IAM path |
| `iam_policy_description` | `string` | `""` | Policy description |
| `iam_policy_version` | `string` | `"2012-10-17"` | Policy version |
| `create_access_key` | `bool` | `false` | Create an access key for the user |
| `github_repository` | `string` | `""` | Repo to push credentials to (e.g. `datablock-dev/my-repo`) |
| `aws_access_key_id_secret_name` | `string` | `"AWS_ACCESS_KEY_ID"` | GitHub secret name for the key ID |
| `aws_secret_access_key_secret_name` | `string` | `"AWS_SECRET_ACCESS_KEY"` | GitHub secret name for the secret |

**Outputs:** `iam_user_name`, `iam_user_arn`, `iam_user_unique_id`, `iam_policy_id`, `iam_policy_arn`, `iam_policy_name`, `access_key_id`, `secret_access_key` (sensitive)

> Requires the `integrations/github` Terraform provider when `github_repository` is set.

---

### `github_oicd`

IAM role for GitHub Actions OIDC authentication — enables keyless AWS access from CI.

```hcl
module "github_oidc" {
  source = "github.com/datablock-dev/.github//terraform-modules/github_oicd?ref=main"

  repository       = "datablock-dev/my-repo"   # required
  project_name     = "my-project"              # required
  oidc_provider_arn = aws_iam_openid_connect_provider.github.arn  # required
}
```

| Variable | Type | Default | Description |
|---|---|---|---|
| `repository` | `string` | — | GitHub repository (e.g. `datablock-dev/my-repo`) |
| `project_name` | `string` | — | Project name used to build unique resource names |
| `oidc_provider_arn` | `string` | — | ARN of the GitHub OIDC provider in AWS |
| `policy` | `list(string)` | `[]` | Additional IAM policy document ARNs to attach |

**Outputs:** `datablock_github_oidc_role_arn`

---

### `lambda_http_service`

Lambda function with an HTTP trigger (API Gateway / Function URL) and an SQS queue.

```hcl
module "api" {
  source = "github.com/datablock-dev/.github//terraform-modules/lambda_http_service?ref=main"

  service_name   = "my-api"   # required
  env_variables  = {          # required
    DATABASE_URL = "..."
  }
}
```

| Variable | Type | Default | Description |
|---|---|---|---|
| `service_name` | `string` | — | Prefix for all resource names |
| `env_variables` | `map(string)` | — | Environment variables for the Lambda |
| `is_fifo` | `bool` | `false` | Whether the SQS queue is FIFO |
| `lambda_handler` | `string` | `"index.handler"` | Handler entrypoint |
| `lambda_runtime` | `string` | `"nodejs22.x"` | Lambda runtime |
| `lambda_timeout` | `number` | `10` | Timeout in seconds |
| `additional_iam_statements` | `list(object)` | `[]` | Extra IAM policy statements for the Lambda role |

**Outputs:** `lambda_function_arn`, `lambda_function_name`, `sqs_queue_url`, `sqs_queue_arn`

---

### `lambda_sqs_service`

Lambda function triggered by SQS messages, with a dead-letter queue.

All resources use the caller's default `aws` provider, so the queue and the
Lambda always land in the same region. To deploy an instance of this module
to a specific region, pass an aliased provider explicitly:

```hcl
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}

module "worker" {
  source = "github.com/datablock-dev/.github//terraform-modules/lambda_sqs_service?ref=main"
  providers = {
    aws = aws.useast1
  }

  service_name          = "my-worker"   # required
  dead_letter_queue_arn = aws_sqs_queue.dlq.arn  # required
  env_variables         = {            # required
    DATABASE_URL = "..."
  }
}
```

| Variable | Type | Default | Description |
|---|---|---|---|
| `service_name` | `string` | — | Prefix for all resource names |
| `dead_letter_queue_arn` | `string` | — | ARN of the dead-letter queue |
| `env_variables` | `map(string)` | — | Environment variables for the Lambda |
| `is_fifo` | `bool` | `false` | Whether the SQS queue is FIFO |
| `max_receive_count` | `number` | `1` | Times a message is received before going to DLQ |
| `lambda_handler` | `string` | `"index.handler"` | Handler entrypoint |
| `lambda_runtime` | `string` | `"nodejs22.x"` | Lambda runtime |
| `lambda_timeout` | `number` | `10` | Timeout in seconds |
| `additional_iam_statements` | `list(object)` | `[]` | Extra IAM policy statements for the Lambda role |
| `queue_policy_statements` | `list(object)` | `[]` | Extra resource-policy statements granting other IAM principals access to the queue |

To let another service's role send messages to this queue, pass a
`queue_policy_statements` entry — `Resource` is always the queue itself, so
you only need `Effect`, `Principal`, and `Action`:

```hcl
queue_policy_statements = [
  {
    Effect    = "Allow"
    Principal = { AWS = aws_iam_role.other_service.arn }
    Action    = ["sqs:SendMessage"]
  }
]
```

**Outputs:** `lambda_function_arn`, `lambda_function_name`, `sqs_queue_url`, `sqs_queue_arn`

---

## Pinning versions

Using `?ref=main` always pulls the latest commit on `main`. For production infrastructure, pin to a specific commit SHA so changes to this repo don't affect you unexpectedly:

```hcl
source = "github.com/datablock-dev/.github//terraform-modules/aws_ecr?ref=abc1234"
```

To update, change the SHA and run `terraform init -upgrade`.

## Adding a new module

1. Create a new directory under `terraform-modules/` with `main.tf`, `variables.tf`, and `outputs.tf`.
2. Add a section for it in this README.
3. Consumers reference it the same way — no publishing or registry needed.
