/*
I'm keeping this file as a placeholder/example and I'm NOT putting
production backend identifiers or secrets here. I create a local,
untracked file `terraform/backend.tf.local` with my real backend values
and initialize Terraform with:

  terraform init -backend-config=terraform/backend.tf.local

An example `terraform/backend.tf.local` (DO NOT commit):

bucket         = "aws-sentiment-analyzer-terraform-state"
key            = "sentiment-analysis/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "aws-sentiment-analyzer-terraform-locks"
encrypt        = true

If I want to keep an example file in the repo, I only put placeholder
values here and keep the real config local and ignored.
*/

terraform {
  # I'm leaving this intentionally empty so I don't accidentally commit a real backend.
}