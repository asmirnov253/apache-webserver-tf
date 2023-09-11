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
  name           = var.dynamodb_table_name # Replace with your desired table name
  billing_mode   = "PROVISIONED"           # You can use "PAY_PER_REQUEST" for on-demand capacity mode
  read_capacity  = 5                       # Adjust read capacity units as needed
  write_capacity = 5                       # Adjust write capacity units as needed

  attribute {
    name = "id"
    type = "N"
  }
  hash_key = "id"
}

resource "aws_vpc" "site_vpc" { # 
  cidr_block = var.vpc_cidr     # Set your VPC IP range
}

# Create Subnets dynamically for VPC
resource "aws_subnet" "subnets" {
  count = var.subnet_count_per_vpc

  vpc_id            = aws_vpc.site_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = format("%s%s", var.region, element(["a", "b"], count.index % 2))
}