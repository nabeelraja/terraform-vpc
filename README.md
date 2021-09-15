# terraform-vpc-exercise
Terraform, Infrastructure as Code! 

It creates; 
* 1 VPC, 
* 1 Public subnet, 
* 1 Internet Gateway, 
* 1 Security Group
* 1 Auto scaling group
* 1 Load balancer
* 1 EC2 (installed a nginx in it)

After cloning the repo, just run these 3 commands

```
ssh-keygen -f rsa
terraform init
terraform plan -out terraform.out
terraform apply terraform.out
```