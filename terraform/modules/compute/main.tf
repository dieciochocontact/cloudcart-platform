data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for app servers"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 python3-pip postgresql
    pip3 install boto3 psycopg2-binary

    cat > /tmp/server.py << 'PYEOF'
    import http.server
    import json
    import socketserver
    import boto3
    import psycopg2
    import urllib.request
    from datetime import datetime, timedelta

    def get_instance_metadata(path):
        try:
            with urllib.request.urlopen(f'http://169.254.169.254/latest/meta-data/{path}', timeout=2) as r:
                return r.read().decode()
        except:
            return 'unknown'

    INSTANCE_ID = get_instance_metadata('instance-id')
    AZ = get_instance_metadata('placement/availability-zone')
    REGION = 'us-east-1'

    def get_db_credentials():
        client = boto3.client('secretsmanager', region_name=REGION)
        secret = client.get_secret_value(SecretId='vaultpay-dev/db-credentials')
        return json.loads(secret['SecretString'])

    def get_db_stats():
        try:
            creds = get_db_credentials()
            conn = psycopg2.connect(
                host=creds['host'],
                database=creds['database'],
                user=creds['username'],
                password=creds['password'],
                port=creds['port'],
                connect_timeout=3
            )
            cur = conn.cursor()
            cur.execute("SELECT version();")
            version = cur.fetchone()[0]
            cur.close()
            conn.close()
            return {'status': 'connected', 'version': version}
        except Exception as e:
            return {'status': 'error', 'message': str(e)}

    def get_metrics():
        try:
            cw = boto3.client('cloudwatch', region_name=REGION)
            end = datetime.utcnow()
            start = end - timedelta(minutes=10)

            cpu = cw.get_metric_statistics(
                Namespace='AWS/EC2',
                MetricName='CPUUtilization',
                Dimensions=[{'Name': 'InstanceId', 'Value': INSTANCE_ID}],
                StartTime=start,
                EndTime=end,
                Period=300,
                Statistics=['Average']
            )
            cpu_val = round(cpu['Datapoints'][-1]['Average'], 2) if cpu['Datapoints'] else 0

            alarms = cw.describe_alarms(AlarmNamePrefix='vaultpay-dev')
            alarm_list = [{'name': a['AlarmName'], 'state': a['StateValue']} for a in alarms['MetricAlarms']]

            return {'cpu_percent': cpu_val, 'alarms': alarm_list, 'instance': INSTANCE_ID}
        except Exception as e:
            return {'error': str(e)}

    class Handler(http.server.BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            pass
        def do_GET(self):
            if self.path == '/health':
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'status': 'healthy', 'instance': INSTANCE_ID, 'az': AZ}).encode())
            elif self.path == '/api/db':
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(get_db_stats()).encode())
            elif self.path == '/api/metrics':
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(get_metrics()).encode())
            else:
                db = get_db_stats()
                db_status = 'Connected to RDS PostgreSQL' if db['status'] == 'connected' else 'Error: ' + db.get('message', 'Unknown')
                self.send_response(200)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self.end_headers()
                html = f'''<!DOCTYPE html>
    <html>
    <head>
        <title>VaultPay Platform</title>
        <meta charset="utf-8">
        <style>
            body {{ font-family: Arial; background: #1a1a2e; color: white; text-align: center; padding: 50px; margin: 0; }}
            .card {{ background: #16213e; padding: 30px; border-radius: 15px; margin: 20px auto; max-width: 600px; }}
            .green {{ color: #00ff88; }}
            .blue {{ color: #00b4d8; }}
            .red {{ color: #e94560; }}
            h1 {{ color: #e94560; font-size: 2em; }}
            .btn {{ background: #e94560; color: white; border: none; padding: 12px 25px; border-radius: 8px; cursor: pointer; font-size: 1em; margin: 8px; }}
            .btn:hover {{ background: #c73652; }}
            .btn-blue {{ background: #00b4d8; }}
            .btn-blue:hover {{ background: #0090ad; }}
            .btn-green {{ background: #00ff88; color: #1a1a2e; }}
            .btn-green:hover {{ background: #00cc70; }}
            #result {{ background: #0f3460; padding: 15px; border-radius: 8px; margin-top: 15px; text-align: left; display: none; font-family: monospace; font-size: 0.9em; }}
        </style>
    </head>
    <body>
        <h1>VaultPay Platform</h1>
        <p style="color:#888">Production-Ready Fintech Infrastructure on AWS</p>

        <div class="card">
            <h2>Tier 2 - Application Server</h2>
            <p class="blue">Instance: {INSTANCE_ID}</p>
            <p class="blue">Availability Zone: {AZ}</p>
            <button class="btn" onclick="checkHealth()">Health Check</button>
            <button class="btn btn-blue" onclick="checkDB()">Database Status</button>
            <button class="btn btn-green" onclick="checkMetrics()">Live Metrics</button>
            <div id="result"></div>
        </div>

        <div class="card">
            <h2>Tier 3 - Database Connection</h2>
            <p class="green">{db_status}</p>
            <p style="color:#888; font-size:0.9em">RDS PostgreSQL via AWS Secrets Manager</p>
        </div>

        <div class="card">
            <h2>Architecture</h2>
            <p style="color:#888">Internet -> ALB -> Auto Scaling Group -> RDS PostgreSQL</p>
            <p style="color:#888">Multi-AZ | Terraform IaC | GitHub Actions CI/CD</p>
            <p style="color:#888">CloudWatch | VPC Flow Logs | CloudTrail | Auto Scaling</p>
        </div>

        <script>
            function checkHealth() {{
                fetch('/health')
                    .then(r => r.json())
                    .then(d => {{
                        document.getElementById('result').style.display = 'block';
                        document.getElementById('result').innerHTML = '<p class="green">Health Check:</p><pre>' + JSON.stringify(d, null, 2) + '</pre>';
                    }});
            }}
            function checkDB() {{
                document.getElementById('result').style.display = 'block';
                document.getElementById('result').innerHTML = '<p class="blue">Checking database...</p>';
                fetch('/api/db')
                    .then(r => r.json())
                    .then(d => {{
                        document.getElementById('result').innerHTML = '<p class="green">Database Status:</p><pre>' + JSON.stringify(d, null, 2) + '</pre>';
                    }});
            }}
            function checkMetrics() {{
                document.getElementById('result').style.display = 'block';
                document.getElementById('result').innerHTML = '<p class="blue">Loading metrics from CloudWatch...</p>';
                fetch('/api/metrics')
                    .then(r => r.json())
                    .then(d => {{
                        let html = '<p class="green">Live Metrics:</p>';
                        html += '<pre>' + JSON.stringify(d, null, 2) + '</pre>';
                        document.getElementById('result').innerHTML = html;
                    }});
            }}
        </script>
    </body>
    </html>'''
                self.wfile.write(html.encode('utf-8'))

    with socketserver.TCPServer(('', 80), Handler) as httpd:
        httpd.serve_forever()
    PYEOF

    nohup python3 /tmp/server.py > /tmp/server.log 2>&1 &
  EOF
}

resource "aws_iam_role" "app" {
  name = "${var.project_name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-app-role"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "secrets_access" {
  name = "secrets-manager-access"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = "arn:aws:secretsmanager:us-east-1:101551113442:secret:vaultpay-dev/db-credentials*"
    }]
  })
}

resource "aws_iam_role_policy" "cloudwatch_read" {
  name = "cloudwatch-read-access"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["cloudwatch:GetMetricStatistics", "cloudwatch:DescribeAlarms", "cloudwatch:ListMetrics"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-app-profile"
  role = aws_iam_role.app.name
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = base64encode(local.user_data)

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app-asg"
    }
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = var.private_app_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]
  min_size            = 3
  max_size            = 6
  desired_capacity    = 3
  health_check_type   = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown                = 120
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown                = 120
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "${var.project_name}-asg-scale-up"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "${var.project_name}-asg-scale-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 20
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}