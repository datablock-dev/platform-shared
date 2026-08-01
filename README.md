# platform-shared

Shared Terraform modules, GitHub Actions workflows, Helm charts, and Kubernetes manifests for the Datablock platform.

## Terraform actions

The repository provides two cloud-authentication-agnostic composite actions:

- `.github/actions/terraform-plan` runs `fmt`, `init`, `validate`, and `plan`, then posts or updates a pull request comment.
- `.github/actions/terraform-apply` optionally removes or imports state during manually dispatched workflows, creates a saved plan, and applies it.

The caller owns checkout and cloud authentication. Credentials exported by preceding steps in the same job—including AWS credentials and Google Application Default Credentials—are inherited by Terraform inside the composite action. This allows each repository to authenticate only to the providers it uses.

### Terraform Plan

The following example authenticates to both AWS and Google before running Terraform:

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
      - name: Create GitHub App token
        id: app-token
        uses: actions/create-github-app-token@v3.2.0
        with:
          client-id: ${{ secrets.GH_APP_ID }}
          private-key: ${{ secrets.GH_APP_PRIVATE_KEY }}
          owner: ${{ github.repository_owner }}

      - name: Check out repository
        uses: actions/checkout@v7
        with:
          token: ${{ steps.app-token.outputs.token }}
          persist-credentials: false

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v6.2.3
        with:
          role-to-assume: ${{ vars.OIDC_ROLE_ARN }}
          aws-region: eu-north-1
          role-session-name: GitHubActions-${{ github.run_id }}

      - name: Assume target AWS account role
        uses: aws-actions/configure-aws-credentials@v6.2.3
        with:
          role-to-assume: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/OrganizationAccountAccessRole
          aws-region: eu-north-1
          role-chaining: true
          role-skip-session-tagging: true

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v3
        with:
          workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}

      - name: Terraform plan
        uses: datablock-dev/platform-shared/.github/actions/terraform-plan@main
        with:
          environment: staging
          app-token: ${{ steps.app-token.outputs.token }}
```

The action expects `backend-<environment>.hcl` in the working directory and selects or creates a Terraform workspace with the same environment name. Its defaults are Terraform `1.10.4` and the `terraform` working directory.

The plan action exposes `fmt-outcome`, `init-outcome`, `validate-outcome`, `plan-outcome`, and `plan-stdout`. It reports all Terraform outcomes in one comment before failing if any required step failed or was skipped. The GitHub App must be able to read any private module repositories and write pull request comments.

### Terraform Apply

Apply uses the same caller-owned checkout and authentication pattern:

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
      - name: Create GitHub App token
        id: app-token
        uses: actions/create-github-app-token@v3.2.0
        with:
          client-id: ${{ secrets.GH_APP_ID }}
          private-key: ${{ secrets.GH_APP_PRIVATE_KEY }}
          owner: ${{ github.repository_owner }}

      - name: Check out repository
        uses: actions/checkout@v7
        with:
          token: ${{ steps.app-token.outputs.token }}
          persist-credentials: false

      # Add the AWS, Google, or other provider authentication required by this
      # repository before calling the composite action.

      - name: Terraform apply
        uses: datablock-dev/platform-shared/.github/actions/terraform-apply@main
        with:
          environment: ${{ inputs.environment }}
          app-token: ${{ steps.app-token.outputs.token }}
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
