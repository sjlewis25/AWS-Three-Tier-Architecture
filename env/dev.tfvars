environment = "dev"
region      = "us-east-1"

vpc_cidr              = "10.0.0.0/16"
public_subnet_cidr    = "10.0.1.0/24"
public_subnet_2_cidr  = "10.0.4.0/24"
private_subnet_1_cidr = "10.0.2.0/24"
private_subnet_2_cidr = "10.0.3.0/24"
availability_zones    = ["us-east-1a", "us-east-1b"]

ami_id        = "ami-0c02fb55956c7d316"
instance_type = "t2.micro"

my_ip = "97.97.238.72/32"

db_name     = "mydb"
db_username = "admin"
db_password = "somepassword"

budget_notification_email = "steven.j.lewis.2024@gmail.com"



