#!make
include .env
export

fmt:
	terraform fmt --recursive

init:
	terraform init -reconfigure \
	--backend-config="lambda-kofax-clearup-smb/terraform.tfstate"


validate:
	terraform validate

plan:
	terraform plan -out terraform.tfplan

apply:
	terraform apply terraform.tfplan

destroy:
	terraform destroy
output:
	terraform output -raw fullpath

.PHONY: fmt init validate plan apply destroy output
