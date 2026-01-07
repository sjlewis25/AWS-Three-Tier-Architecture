# Troubleshooting Guide

## Issues Encountered During Deployment

### Issue 1: Terraform State Lock Conflict

**Symptoms**: 
- `terraform apply` failed with error: "Error acquiring the state lock"
- DynamoDB showed existing lock from previous failed deployment

**Root Cause**: 
Previous terraform run was interrupted (Ctrl+C), leaving state file locked in DynamoDB

**Resolution**:
```bash
# Forcefully unlock the state
terraform force-unlock <lock-id-from-error>

# Verified state was clean
terraform plan

# Re-ran apply successfully
terraform apply -var-file="dev.tfvars"
```

**Time to Resolution**: 5 minutes

---

### Issue 2: EC2 User Data Script Not Executing

**Symptoms**:
- EC2 instances launched but Apache not running
- ALB health checks failing
- Manual SSH showed Apache service not installed

**Root Cause**:
User data script had syntax error preventing Apache installation from completing

**Resolution**:
```bash
# SSH'd into instance to check
ssh -i key.pem ec2-user@<instance-ip>

# Checked cloud-init logs
sudo cat /var/log/cloud-init-output.log

# Found error in yum install command
# Fixed user data script in launch template
# Terminated old instances, let ASG launch new ones with corrected script
```

**Time to Resolution**: 20 minutes

---

### Issue 3: RDS Connection Timeout from EC2

**Symptoms**:
- Application logs showing "Can't connect to MySQL server"
- Connection attempts timing out after 60 seconds
- RDS instance showing "Available" status

**Root Cause**:
RDS security group missing ingress rule allowing traffic from EC2 security group on port 3306

**Resolution**:
```bash
# Checked RDS security group rules
aws ec2 describe-security-groups --group-ids <rds-sg-id>

# Added missing ingress rule
aws ec2 authorize-security-group-ingress \
  --group-id <rds-sg-id> \
  --protocol tcp \
  --port 3306 \
  --source-group <ec2-sg-id>

# Tested connection from EC2
mysql -h <rds-endpoint> -u admin -p
# Connection successful
```

**Time to Resolution**: 12 minutes

---

### Issue 4: ALB Returning 502 Bad Gateway

**Symptoms**:
- ALB endpoint accessible but returning 502 errors
- Target group showing "unhealthy" status
- EC2 instances running and Apache active

**Root Cause**:
Security group on EC2 instances not configured to allow inbound traffic from ALB security group

**Resolution**:
```bash
# Identified the issue via target group health check details
# Updated EC2 security group to allow traffic from ALB SG
aws ec2 authorize-security-group-ingress \
  --group-id <ec2-sg-id> \
  --protocol tcp \
  --port 80 \
  --source-group <alb-sg-id>

# Health checks started passing within 30 seconds
# ALB began routing traffic successfully
```

**Time to Resolution**: 8 minutes

---

## Common Troubleshooting Commands

### Check EC2 Instance Status
```bash
aws ec2 describe-instances --instance-ids <instance-id> --query 'Reservations[*].Instances[*].[State.Name,PublicIpAddress]'
```

### View Target Group Health
```bash
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

### Check RDS Status
```bash
aws rds describe-db-instances --db-instance-identifier <db-name> --query 'DBInstances[*].[DBInstanceStatus,Endpoint.Address]'
```

### Review CloudWatch Logs
```bash
aws logs tail /aws/ec2/user-data --follow
```

### Verify Security Group Rules
```bash
aws ec2 describe-security-groups --group-ids <sg-id> --query 'SecurityGroups[*].IpPermissions'
```