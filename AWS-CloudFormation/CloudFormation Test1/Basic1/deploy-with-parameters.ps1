#Create AWS CloudFormation Stack
aws cloudformation create-stack --stack-name vpc-production `
                                --template-url https://s3.amazonaws.com/architecting-operational-excellence-aws/vpc.yaml `
                                --parameters ParameterKey=VpcCIDR,ParameterValue=10.8.0.0/22 `
                                             ParameterKey=PublicSubnet1CIDR,ParameterValue=10.8.1.0/24 `
                                             ParameterKey=PublicSubnet2CIDR,ParameterValue=10.8.2.0/24


#Output should be:
#{
#    "StackId": "arn:aws:cloudformation:eu-central-1:113493058526:stack/vpc-production/f6f85560-69d2-11ea-a46d-026925054f2e"
#}

#Check status:
aws cloudformation describe-stacks

#List Stack details:
aws cloudformation list-stack-resources --stack-name vpc-production

#Help about intrinsic functions:
#benpiper.com/aws-cf-if