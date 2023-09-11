## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.16.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.website_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_profile"></a> [profile](#input\_profile) | The AWS profile to use for authentication. | `string` | `"default"` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region where resources will be provisioned. | `string` | `"eu-west-3"` | no |
| <a name="input_shared_credentials_file"></a> [shared\_credentials\_file](#input\_shared\_credentials\_file) | The path to the shared AWS credentials file. | `string` | `"~/.aws/credentials"` | no |

## Outputs

No outputs.
