terraform {
  backend "s3" {
    bucket       = "2nd-cicd-project-tfstate-667736132185"
    key          = "terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
    encrypt      = true
  }
}
