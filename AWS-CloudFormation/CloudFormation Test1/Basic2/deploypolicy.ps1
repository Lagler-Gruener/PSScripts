#Create Stack with policy
aws cloudformation create-stack --stack-name vpc-production `
                                --template-url https://s3.amazonaws.com/architecting-operational-excellence-aws/vpc.yaml `
                                --stack-policy-url https://s3.amazonaws.com/architecting-operational-excellence-aws/vpc-policy.json

#Test stack policy
#In my policy, I prevent to update the VPC
#I'll try to update the VPC with the following command:

aws cloudformation update-stack --stack-name vpc-production `
                                --template-url https://s3.amazonaws.com/architecting-operational-excellence-aws/vpc.yaml `
                                --parameters ParameterKey=VpcCIDR,ParameterValue=10.7.0.0/22 `
                                             ParameterKey=PublicSubnet1CIDR,ParameterValue=10.7.1.0/24 `
                                             ParameterKey=PublicSubnet2CIDR,ParameterValue=10.7.2.0/24

#You should get an error at the CloudFormation console!

#Update Stack policy
aws cloudformation update-stack --stack-name vpc-production `
                                --template-url https://s3.amazonaws.com/architectingoperational-excellence-aws/vpc.yaml `
                                --parameters ParameterKey=VpcCIDR,ParameterValue=10.7.0.0/22 `
                                --stack-policy-during-update-url https://s3.amazonaws.com/architecting-operational-excellenceaws/policy-override.json
