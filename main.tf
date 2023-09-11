terraform {
  backend "s3" {
    bucket  = "apachewebserver.state"
    key     = "terraform.tfstate"
    region  = "eu-west-3"
    encrypt = true
    acl     = "private"
  }
}

# Configure the AWS Provider
provider "aws" {
  region                   = var.region
  shared_credentials_files = [var.shared_credentials_file]
  profile                  = var.profile
}

resource "aws_dynamodb_table" "website_table" {
  name           = "WebsiteTable" # Replace with your desired table name
  billing_mode   = "PROVISIONED"  # You can use "PAY_PER_REQUEST" for on-demand capacity mode
  read_capacity  = 5              # Adjust read capacity units as needed
  write_capacity = 5              # Adjust write capacity units as needed

  attribute {
    name = "id"
    type = "N"
  }
  hash_key = "id"
}

