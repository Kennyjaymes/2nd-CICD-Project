terraform {
  backend "s3" {
    bucket         = "2nd-cicd-project-tfstate-667736132185"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "2nd-cicd-project-tfstate-lock"
    encrypt        = true
  }
}
