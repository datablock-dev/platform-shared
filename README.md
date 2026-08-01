# platform-shared

Shared Terraform modules, GitHub Actions workflows, Helm charts, and Kubernetes manifests for the Datablock platform.

## Terraform actions

The repository provides two reusable composite actions:

- `.github/actions/terraform-plan` runs `fmt`, `init`, `validate`, and `plan`, then posts or updates a pull request comment.
- `.github/actions/terraform-apply` optionally removes or imports state during manually dispatched workflows, creates a saved plan, and applies it.

Callers can provide `app-id` and `app-private-key` to let the action create a token and check out the repository, or perform checkout themselves and pass `app-token`. Both actions can optionally perform the standard two-stage AWS role assumption when `aws-oidc-role-arn` and `aws-account-id` are provided. If either input is empty, both AWS steps are skipped. Credentials exported by preceding authentication steps, including Google Application Default Credentials, are inherited by Terraform.

### Terraform Plan

The following example authenticates to Google before the action and lets the action authenticate to AWS:

```yaml
name: Terraform Plan

on:
  pull_request:

jobs:
  plan:
    runs-on: arc-runner-set
    permissions:
      contents: read
      id-token: write
      pull-requests: write
    steps:
      # Google authentication creates its credentials file in the workspace,
      # so check out once before authenticating. The action's App-token
      # checkout uses clean: false and preserves this file.
      - name: Check out repository
        uses: actions/checkout@v7
        with:
          persist-credentials: false

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v3
        with:
          workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}

      - name: Terraform plan
        uses: datablock-dev/platform-shared/.github/actions/terraform-plan@main
        with:
          environment: staging
          aws-oidc-role-arn: ${{ vars.OIDC_ROLE_ARN }}
          aws-account-id: ${{ vars.AWS_ACCOUNT_ID }}
          app-id: ${{ secrets.GH_APP_ID }}
          app-private-key: ${{ secrets.GH_APP_PRIVATE_KEY }}
```

When `app-id` and `app-private-key` are provided together, the action creates a GitHub App token and checks out the repository with `clean: false`. Existing callers can instead perform checkout themselves and pass `app-token`. The action expects `backend-<environment>.hcl` in the working directory and selects or creates a Terraform workspace with the same environment name. Its defaults are Terraform `1.10.4` and the `terraform` working directory.

The plan action exposes `fmt-outcome`, `init-outcome`, `validate-outcome`, `plan-outcome`, and `plan-stdout`. It reports all Terraform outcomes in one comment before failing if any required step failed or was skipped. Set `summary: "false"` to disable the comment. The GitHub App must be able to read any private module repositories and write pull request comments.

### Terraform Apply

Apply uses the same caller-owned checkout and optional AWS authentication pattern:

```yaml
name: Terraform Apply

on:
  workflow_dispatch:
    inputs:
      environment:
        description: Environment to apply
        required: true
        type: choice
        options:
          - staging
          - production
      state-remove:
        description: Optional space-separated resource addresses to remove
        required: false
        type: string
      state-import:
        description: Optional address=id pairs to import
        required: false
        type: string

jobs:
  apply:
    runs-on: arc-runner-set
    environment: ${{ inputs.environment }}
    permissions:
      contents: read
      id-token: write
    steps:
      - name: Terraform apply
        uses: datablock-dev/platform-shared/.github/actions/terraform-apply@main
        with:
          environment: ${{ inputs.environment }}
          aws-oidc-role-arn: ${{ vars.OIDC_ROLE_ARN }}
          aws-account-id: ${{ vars.AWS_ACCOUNT_ID }}
          app-id: ${{ secrets.GH_APP_ID }}
          app-private-key: ${{ secrets.GH_APP_PRIVATE_KEY }}
          state-remove: ${{ inputs.state-remove }}
          state-import: ${{ inputs.state-import }}
```

State operations only run for `workflow_dispatch` events. `state-remove` accepts whitespace-separated resource addresses. `state-import` accepts whitespace-separated `address=id` pairs; IDs containing whitespace are not supported by this input format.

### Reusable AWS plan workflow

Repositories that only need the standard two-stage AWS role assumption can call `.github/workflows/reusable-terraform-plan.yml`:

```yaml
jobs:
  plan:
    permissions:
      contents: read
      id-token: write
      pull-requests: write
    uses: datablock-dev/platform-shared/.github/workflows/reusable-terraform-plan.yml@main
    with:
      environment: staging
      aws-account-id: ${{ vars.AWS_ACCOUNT_ID }}
    secrets:
      gh-app-id: ${{ secrets.GH_APP_ID }}
      gh-app-private-key: ${{ secrets.GH_APP_PRIVATE_KEY }}
```

The reusable workflow handles checkout and AWS authentication internally. GitHub does not allow a caller to insert arbitrary steps into a called workflow's job, so repositories needing Google authentication or different AWS authentication should use the composite action in a regular job instead.

The reusable workflow additionally accepts `working-directory`, `runs-on`, and `terraform-version`, plus an optional `tf-vars` secret containing newline-separated `KEY=VALUE` entries.
