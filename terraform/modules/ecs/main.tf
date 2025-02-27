###################################
# ECS Cluster
###################################
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"

  # Optional: Enable Container Insights
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.environment}-cluster"
    Environment = var.environment
  }
}

###################################
# ECR Repository (for your Docker images)
###################################
resource "aws_ecr_repository" "main" {
  name                 = "${var.environment}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.environment}-ecr"
    Environment = var.environment
  }
}

###################################
# IAM Role for ECS Task Execution
###################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Allow ECS tasks to pull from ECR & push logs to CloudWatch
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Optional: read from SSM
resource "aws_iam_role_policy_attachment" "ecs_task_ssm_access" {
  count      = 1
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# Optional: read-only S3
resource "aws_iam_role_policy_attachment" "ecs_task_s3_access" {
  count      = var.s3_readonly ? 1 : 0
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

###################################
# CloudWatch Log Group for Fargate tasks
###################################
resource "aws_cloudwatch_log_group" "ecs_app" {
  name              = "/ecs/${var.environment}-app"
  retention_in_days = 7

  tags = {
    Name        = "${var.environment}-logs"
    Environment = var.environment
  }
}

###################################
# SSM Parameter Store
###################################

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.environment}/database/password"
  description = "DB password for ${var.environment}"
  type        = "SecureString"
  value       = var.db_password
}


###################################
# ECS Task Definition (FARGATE)
###################################
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}-app"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.environment}-app",
      image     = "${aws_ecr_repository.main.repository_url}:latest",
      essential = true,

      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port  # for Fargate + awsvpc, containerPort == hostPort is allowed
          protocol      = "tcp"
        }
      ],

      secrets = [
        {
          name      = "DB_PASSWORD",
          valueFrom = aws_ssm_parameter.db_password.arn
        }
      ],
      environment = [
        { name = "DB_HOST", value = var.db_host },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_USER", value = var.db_user },
      ],

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_app.name,
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.environment}-taskdef"
    Environment = var.environment
  }
}

###################################
# ECS Service (FARGATE)
###################################
resource "aws_ecs_service" "app" {
  name            = "${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids   # public or private subnets
    security_groups  = [var.app_security_group_id]
    assign_public_ip = true # Required for task to be able to connect to the internet
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "${var.environment}-app"
    container_port   = var.app_port
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]

  tags = {
    Name        = "${var.environment}-service"
    Environment = var.environment
  }
}
