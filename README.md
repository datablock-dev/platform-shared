# platform-shared
Shared Terraform modules, reusable GitHub Actions workflows, Helm charts, and Kubernetes manifests for the Datablock platform.

## Terraform plan CI

The plan pipeline ships in two forms. Both run `terraform fmt` / `init` /
`validate` / `plan` and post the results as a single, continuously-updated PR
comment; failures are collected first so the comment is always written, then the
step fails.

- **`.github/actions/terraform-plan`** — a composite action. You own the job:
  checkout, cloud auth, environment, and any extra steps before or after. Use
  this unless you have a reason not to.
- **`.github/workflows/reusable-terraform-plan.yml`** — a `workflow_call`
  wrapper around the action that also does checkout and GCP auth for you. Less
  boilerplate, no room to insert your own steps.

### Composite action

```yaml
jobs:
  plan:
    name: Plan
    runs-on: arc-runner-set
    if: github.event_name == 'pull_request'
    concurrency:
      group: ${{ github.repository }}-${{ github.workflow }}-plan-${{ github.ref }}
      cancel-in-progress: true
    permissions:
      contents: read
      id-token: write
      pull-requests: write
    env:
      TF_VAR_cloudflare_token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
      TF_VAR_cosmoner_zone_id: ${{ vars.COSMONER_COM_ZONE_ID }}
    steps:
      - uses: actions/create-github-app-token@v3.2.0
        id: app-token
        with:
          client-id: ${{ secrets.GH_APP_ID }}
          private-key: ${{ secrets.GH_APP_PRIVATE_KEY }}
          owner: ${{ github.repository_owner }}

      - uses: actions/checkout@v7
        with:
          token: ${{ steps.app-token.outputs.token }}
          persist-credentials: false

      - uses: google-github-actions/auth@v3
        with:
          workload_identity_provider: projects/867488391395/locations/global/workloadIdentityPools/github-actions-pool/providers/github
          service_account: terraform@datablock-407514.iam.gserviceaccount.com

      - uses: google-github-actions/setup-gcloud@v3

      # ...any other setup you need goes here...

      - uses: datablock-dev/platform-shared/.github/actions/terraform-plan@main
        with:
          working-directory: terraform
          workspace: production
          github-token: ${{ steps.app-token.outputs.token }}
```

Because the job is yours, workflow- and job-level `env:` reaches Terraform
normally — no `tf-vars` plumbing needed.

**Inputs**

| Input | Default | Description |
| --- | --- | --- |
| `working-directory` | `terraform` | Terraform root module directory. |
| `workspace` | `production` | Workspace to select, creating it if missing. Empty stays on `default`. |
| `setup-terraform` | `true` | Install Terraform. Set `false` if the job already ran `hashicorp/setup-terraform`. |
| `terraform-version` | `latest` | Version to install. Ignored when `setup-terraform` is `false`. |
| `github-token` | `${{ github.token }}` | Token for private module sources, `TF_VAR_github_token`, and the PR comment. Pass a GitHub App token if modules live in other private repos. |
| `configure-git-credentials` | `true` | Rewrite `github.com` URLs to use `github-token` for private module sources. |
| `plan-args` | `""` | Extra arguments for `terraform plan`, e.g. `-var-file=prod.tfvars`. |
| `comment-on-pr` | `true` | Post the results comment. Ignored outside `pull_request` events. |
| `fail-on-error` | `true` | Fail the step when fmt/validate/plan failed. Set `false` to branch on the outputs instead. |

**Outputs:** `fmt-outcome`, `init-outcome`, `validate-outcome`, `plan-outcome`
(each `success` or `failure`) and `plan-stdout`.

### Reusable workflow

```yaml
jobs:
  plan:
    if: github.event_name == 'pull_request'
    concurrency:
      group: ${{ github.repository }}-${{ github.workflow }}-plan-${{ github.ref }}
      cancel-in-progress: true
    permissions:
      contents: read
      id-token: write
      pull-requests: write
    uses: datablock-dev/platform-shared/.github/workflows/reusable-terraform-plan.yml@main
    with:
      working-directory: terraform
      workspace: production
      workload-identity-provider: projects/867488391395/locations/global/workloadIdentityPools/github-actions-pool/providers/github
      service-account: terraform@datablock-407514.iam.gserviceaccount.com
    secrets:
      gh-app-id: ${{ secrets.GH_APP_ID }}
      gh-app-private-key: ${{ secrets.GH_APP_PRIVATE_KEY }}
      tf-vars: |
        AWS_ACCESS_KEY_ID=${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY=${{ secrets.AWS_SECRET_ACCESS_KEY }}
        TF_VAR_cloudflare_token=${{ secrets.CLOUDFLARE_API_TOKEN }}
        TF_VAR_cosmoner_zone_id=${{ vars.COSMONER_COM_ZONE_ID }}
```

**Inputs**

| Input | Default | Description |
| --- | --- | --- |
| `working-directory` | `terraform` | Terraform root module directory. |
| `runs-on` | `arc-runner-set` | Runner label for the plan job. |
| `terraform-version` | `latest` | Terraform version to install. |
| `workspace` | `production` | Workspace to select, creating it if missing. Empty stays on `default`. |
| `workload-identity-provider` | `""` | GCP workload identity provider. Empty skips GCP auth entirely. |
| `service-account` | `""` | GCP service account to impersonate. |
| `setup-gcloud` | `true` | Install the gcloud CLI after GCP auth. |
| `plan-args` | `""` | Extra arguments for `terraform plan`, e.g. `-var-file=prod.tfvars`. |
| `comment-on-pr` | `true` | Post the results comment. Ignored outside `pull_request` events. |

**Secrets**

| Secret | Required | Description |
| --- | --- | --- |
| `gh-app-id` | yes | GitHub App client ID, used to read private Terraform modules. |
| `gh-app-private-key` | yes | GitHub App private key. |
| `tf-vars` | no | Newline-separated `KEY=VALUE` pairs exported into the job environment. Every value is masked in the logs; values may not contain newlines. |

**Notes**

- `permissions`, `concurrency` and the job-level `if` stay in the calling
  workflow. A called workflow can only narrow the permissions the caller
  granted, so the caller must grant `id-token: write` (GCP auth) and
  `pull-requests: write` (the plan comment).
- Workflow-level `env:` in the caller does **not** propagate into a reusable
  workflow. Anything Terraform needs from the environment has to go through
  `tf-vars`.
- `TF_VAR_github_token` is set automatically from the GitHub App token, so it
  should not be passed via `tf-vars`.
- The comment marker is keyed on `working-directory`, so several root modules
  can plan on the same PR without overwriting each other's comment.
- The workflow references the composite action by full path pinned to `@main`,
  because a relative `uses: ./` inside a reusable workflow resolves against the
  *caller's* checkout rather than this repository. If you pin the workflow to a
  tag, update that reference to match or the two will drift apart.
