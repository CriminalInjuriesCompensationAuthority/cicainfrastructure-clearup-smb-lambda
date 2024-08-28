# cicainfrastructure-lambda-smb-clearup
Lambda code for clearing up file share folders which have "DELETE" flag added after processing.

This code creates a lambda function in an existing VPC. It uses smbprotocol to connect to an existing file share. This can be an AWS storage gateway file share or an on-premise file share if there is connectivity between on-premise and the VPC through Direct Connect or customer gateway.

Required: Create `.env` file from copy of `env.example`. Update this with AWS CLI `profile` that has permission to read state file.

You will also need a `profile` in your `credentials` file for each environment and a `terraform.tfvars` file similar to below:
```hcl
profile = {
  "UAT"            = "uat-profile"
  "Production"     = "prod-profile"
  "Development"    = "dev-profile"
}
``` 

Usage: 
1. ensure you are in the correct terraform workspace for environment. e.g. `terraform workspace select -or-create development`.
2. Run `make plan`
3. Check you are happy with any changes
4. Run `make apply`

Resources created by this code are: Lambda Function, Lambda Layer, Security Group, AWS Secrets Manager Secret containing dummy credentials for host, share, username, password. The secret should be updated with valid credentials before running the lambda function.

This code is based on this [AWS Blog](https://aws.amazon.com/blogs/storage/enabling-smb-access-for-serverless-workloads/) and corresponding [repo](https://github.com/aws-samples/aws-lambda-smb-shares/tree/main/src/pythonSMB/function).

Todo: Add github workflows for automation. Format alerts with information on environment and runbook.