#In that solution we define two stacks and the secound stack use the output from the first one
aws cloudformation create-stack --stack-name alb-production `
                                --template-url https://s3.amazonaws.com/architecting-operational-excellence-aws/load-balancer.yaml `
                                --parameters ParameterKey=VPCStackName,ParameterValue=vpc-production