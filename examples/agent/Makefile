.PHONY: default apply test exec clean check-profile

default:
	@echo "Read the readme"

apply: check-profile
	@# Apply this example.
	terraform init && AWS_PROFILE=$(profile) terraform apply -auto-approve

test: check-profile
	@# Test agent reachability via the health endpoint.
	@# This command expects that you have have applied this example. Use exec to do both steps.
	@temp_role=$$(aws sts assume-role --profile $(profile) \
									  --role-arn "$$(terraform output --raw invoker_role_arn)" \
									  --external-id "$$(terraform output --raw invoker_role_external_id)" \
									  --role-session-name 'mc-agent-test'); \
	AWS_ACCESS_KEY_ID=$$(jq -r .Credentials.AccessKeyId <<<"$$temp_role") \
	AWS_SECRET_ACCESS_KEY=$$(jq -r .Credentials.SecretAccessKey <<<"$$temp_role") \
	AWS_SESSION_TOKEN=$$(jq -r .Credentials.SessionToken <<<"$$temp_role") \
	AWS_REGION=$$(terraform output --raw function_arn | cut -d':' -f4) \
	  aws lambda invoke \
	  --function-name $$(terraform output --raw function_arn) \
	  --cli-binary-format raw-in-base64-out \
	  --payload '{"path": "/api/v1/test/health", "httpMethod": "GET", "queryStringParameters": {"trace_id": "123456789", "full": true}}' \
	  /dev/stdout | jq '.body | select( . != null ) | fromjson'

exec: apply sleep-30 test  # Sleep to wait on initial IAM propagation. Subsequent usage should require no delay.

clean: check-profile
	@# Delete this example.
	@# WARNING -- This command will delete resources and local state files. This is unrecoverable.
	AWS_PROFILE=$(profile) terraform destroy -auto-approve && rm -rf .terraform* terraform.tfstate*

sleep-%:
	sleep $(@:sleep-%=%)

check-profile:
	@[ "${profile}" ] || ( echo "profile is not set"; exit 1 )