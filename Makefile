.PHONY: default sanity-check test

default:
	@echo "Read the readme"

sanity-check:
	# Validate TF configuration files and formatting. Used in CI pipeline.
	terraform init -backend=false
	terraform fmt -recursive -check -diff
	terraform validate

test:
	# Offline module tests with a mocked AWS provider (Terraform >= 1.7).
	terraform init -backend=false
	terraform test
