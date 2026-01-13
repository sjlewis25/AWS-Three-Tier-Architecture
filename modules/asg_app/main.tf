resource "aws_launch_template" "app" {
  name_prefix   = "${var.name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  # IAM instance profile for Secrets Manager access
  iam_instance_profile {
    name = "ec2_profile"  
  }

  # Pass the correct variables to user_data
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_host     = var.db_host
    db_user     = var.db_user
    db_password = var.db_password
  }))

  # Network settings for public IP (simplified)
  network_interfaces {
    associate_public_ip_address = true
    device_index                = 0
    security_groups             = [var.security_group_id]
    # DO NOT specify subnet_id here - let ASG handle it
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name = var.name
      },
      var.common_tags
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.name}-asg"
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  health_check_type         = "ELB"
  health_check_grace_period = 300  # ← Increased to 5 minutes for app startup
  vpc_zone_identifier       = var.subnet_ids  # ← This works now
  target_group_arns         = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"  # ← Use $Latest instead of latest_version
  }

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

