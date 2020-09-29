#In that solution, we deploy an CloudFormation stack, that contains an nested stack
aws cloudformation create-stack --stack-name auto-scalling-production `
                                --template-url https://s3.amazonaws.com/architecting-operational-excellence-aws/auto-scaling.yaml `
                                --parameters ParameterKey=VPCStackName,ParameterValue=vpc-production `
                                             ParameterKey=KeyName,ParameterValue=home-keypair `
                                             --capabilities CAPABILITY_NAMED_IAM