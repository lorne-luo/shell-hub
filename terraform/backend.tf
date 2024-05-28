terraform {
  backend "s3" {
    bucket  = "terraform-tfstate-lorne"
    key     = "shell-hub/shell-hub.tfstate"
    region  = "ap-southeast-2"
    encrypt = true
    #     dynamodb_table = "terraform_tf_lockid"
  }
}