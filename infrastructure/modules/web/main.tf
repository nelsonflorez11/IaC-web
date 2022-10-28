data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "for-web"  

  ingress {
    description      = "from port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "from port 443"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "from ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.ip
    
  }  

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "server-web"
  }
  
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "for_lb_sg"  

  ingress {
    description      = "from port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "from port 443"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  } 

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "alb_sg"
  }
  
}

resource "aws_launch_template" "web" {
  name_prefix   = "web"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.small"
  key_name = "BootcampDevOps"
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data = filebase64("./scripts/DevOps.sh")
  tag_specifications {
  resource_type = "instance"
  tags = {
      Name = "web"
    }
  } 
  
}

resource "aws_autoscaling_group" "web" {
  name               = "web"
  availability_zones = var.availability_zone_names
  desired_capacity   = 2
  max_size           = 5
  min_size           = 1

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.web.id
        version = "$Latest"
      }

      override {
        instance_type     = "t2.micro"        
      }

      override {
        instance_type     = "t2.medium"        
      }

    }
  }
      
  lifecycle {
      ignore_changes = [load_balancers, target_group_arns]
  }
  
}

resource "aws_alb" "lb-web" {
  name               = "lb-web"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnets

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "web" {
  name     = "web"
  port     = 80
  protocol = "HTTP"
  
  vpc_id   = var.vpc
}

resource "aws_autoscaling_attachment" "web" {
  lb_target_group_arn = aws_lb_target_group.web.arn
  autoscaling_group_name = aws_autoscaling_group.web.id
  
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_alb.lb-web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}





