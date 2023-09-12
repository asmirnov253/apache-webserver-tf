terraform {
  backend "s3" {
    bucket  = "apache-webserver-state"
    key     = "terraform.tfstate"
    region  = "eu-west-3"
    encrypt = true
    acl     = "private"
  }
}

# Configure the AWS Provider
provider "aws" {
  region                   = var.region
  shared_credentials_files = [var.shared_credentials_file]
  profile                  = var.profile
}

resource "aws_dynamodb_table" "website_table" {
  name           = var.dynamodb_table_name # Replace with your desired table name
  billing_mode   = "PROVISIONED"           # You can use "PAY_PER_REQUEST" for on-demand capacity mode
  read_capacity  = 5                       # Adjust read capacity units as needed
  write_capacity = 5                       # Adjust write capacity units as needed

  attribute {
    name = "id"
    type = "N"
  }
  hash_key = "id"
}

module "s3_bucket" {
  source       = "./modules/s3_bucket" # Path to your module directory
  bucket_names = var.bucket_names      # You can customize the bucket name here if needed
}

resource "aws_vpc" "site_vpc" { # 
  cidr_block = var.vpc_cidr     # Set your VPC IP range
  tags = {
    Name = "site-vpc"
  }
}

# Create Subnets dynamically for VPC
resource "aws_subnet" "subnets" {
  count = var.subnet_count_per_vpc

  vpc_id            = aws_vpc.site_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = format("%s%s", var.region, element(["a", "b"], count.index % 2))
}

resource "aws_internet_gateway" "site-gateway" {
  vpc_id = "vpc-035aae215ad49e162"  # Replace with your VPC ID
}

resource "aws_route" "example" {
  route_table_id         = "rtb-054b953217e7481fc"  # Replace with your route table ID
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.site-gateway.id
}

#  IAM Role granting PUT/GET access to S3 Bucket
resource "aws_iam_role" "website_role" {
  name = "website-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3-access-policy"
  description = "Policy to grant PUT/GET access to an S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = ["s3:GetObject", "s3:PutObject"],
      Effect   = "Allow",
      Resource = "arn:aws:s3:::apache-site-bucket/*" # Replace with your S3 bucket ARN
    }]
  })
}

resource "aws_iam_policy_attachment" "s3_access_attachment" {
  name       = "s3-access-attachment"
  policy_arn = aws_iam_policy.s3_access_policy.arn
  roles      = [aws_iam_role.website_role.name]
}

resource "aws_iam_instance_profile" "website_instance_profile" {
  name = "website-instance-profile"
  role = aws_iam_role.website_role.name
}

#  IAM Role granting Session Manager access
resource "aws_iam_policy" "session_manager_policy" {
  name        = "session-manager-policy"
  description = "Policy to grant Session Manager access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = "ssm:StartSession",
      Effect   = "Allow",
      Resource = "*"
    }]
  })
}

resource "aws_iam_policy_attachment" "session_manager_attachment" {
  name       = "session_manager-attachment"
  policy_arn = aws_iam_policy.session_manager_policy.arn
  roles      = [aws_iam_role.website_role.name]
}

# Create a security group for the EC2 instances (adjust security group rules as needed)
resource "aws_security_group" "webserver_sg" {
  name        = "webserver-sg"
  description = "Security group for web server instances"
  #vpc_id      = "vpc-035aae215ad49e162"
  vpc_id      = aws_vpc.site_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a launch configuration
resource "aws_launch_configuration" "webserver_lc" {
  name_prefix            = "webserver-lc-"
  image_id               = "ami-02bbe13b2401b91f9" # Specify the desired AMI ID
  instance_type          = "t2.micro"              # Specify the desired instance type
  security_groups        = ["sg-091ce69b703308b93"]
  iam_instance_profile   = aws_iam_instance_profile.website_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd php
              service httpd start
              chkconfig httpd on
              aws s3 cp s3://apache-site-bucket/index.php /var/www/html/index.html
              EOF
}

# Create an Auto Scaling Group using the launch configuration
resource "aws_autoscaling_group" "webserver_asg" {
  name          = "webserver-asg"
  launch_configuration = aws_launch_configuration.webserver_lc.name
  min_size             = 1
  max_size             = 2                        # Adjust as needed
  desired_capacity     = 1                        # Adjust as needed
  vpc_zone_identifier  = [ "subnet-0d635927f2d5f4685", "subnet-0650e10d59a4c9451" ] # Specify your subnet ID(s)

  # Add tags as needed
  tag {
    key                 = "Name"
    value               = "WebServerInstance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "webserver_asg_policy" {
  name                  = "webserver-asg-policy"
  scaling_adjustment    = 1
  adjustment_type       = "ChangeInCapacity"
  cooldown              = 300
  policy_type           = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.webserver_asg.name
}

resource "aws_cloudwatch_metric_alarm" "webserver-asg-alarm" {
  alarm_name          = "webserver-asg-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Scale up when CPU utilization is greater than or equal to 70%"
  alarm_actions       = [aws_autoscaling_policy.webserver_asg_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webserver_asg.name
  }
}

resource "aws_lb" "site-alb" {
  name               = "site-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-091ce69b703308b93"]
  subnets            = [ "subnet-0d635927f2d5f4685", "subnet-0650e10d59a4c9451" ]  # Replace with your desired subnets
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "site-target-group" {
  name     = "site-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.site_vpc.id  # Replace with your VPC ID

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = 80
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "site-lb-listener" {
  load_balancer_arn = aws_lb.site-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "site-lb-listener-rule" {
  listener_arn = aws_lb_listener.site-lb-listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.site-target-group.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# resource "aws_route53_zone" "apachewebsite" {
#   name = "your-domain.com"  # Replace with your actual domain name
# }

# resource "aws_route53_record" "website" {
#   zone_id = "your_zone_id"  # Replace with your Route 53 hosted zone ID
#   name    = "your-domain.com"  # Replace with your domain name
#   type    = "A"
#   alias {
#     name                   = aws_lb.example.dns_name  # The DNS name of your ALB
#     zone_id                = aws_lb.example.zone_id  # The zone ID of your ALB
#     evaluate_target_health = true
#   }
# }