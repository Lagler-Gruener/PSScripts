#Delete the aws stack created bevor. This will also delete all created ressources from the aws stack
aws cloudformation delete-stack --stack-name vpc-production
#No output

#Check delete State:
aws cloudformation describe-stacks --stack-name vpc-production

#Stackstatus: Delete_in_progress
