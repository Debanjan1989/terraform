provider "google" {
  project = var.project_id
  region  = "us-central1"
}

resource "google_service_account" "dbt_ci" {
  account_id   = "dbt-ci-sa"
  display_name = "Service account for dbt CI/CD"
}

resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Identity Pool"
  description               = "Federated pool for GitHub Actions"
  location                  = "global"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name = "GitHub OIDC Provider"
  location     = "global"
  attribute_mapping = {
    "google.subject"        = "assertion.sub"
    "attribute.repository"  = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "allow_impersonation" {
  service_account_id = google_service_account.dbt_ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}
