terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  node_group_sg_name = "eks-${aws_eks_cluster.this.name}-${var.node_group_name}-SG"
}

resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-${replace(var.region, "-", "")}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "service_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role" "eks_node" {
  name = "${var.project_name}-${replace(var.region, "-", "")}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "registry_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_security_group" "cluster" {
  name        = "${var.project_name}-${replace(var.region, "-", "")}-eks-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${replace(var.region, "-", "")}-eks-cluster-sg"
  }
}

resource "aws_eks_cluster" "this" {
  name     = "${var.project_name}-${replace(var.region, "-", "")}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids             = var.private_subnet_ids
    endpoint_public_access = true
    public_access_cidrs    = ["0.0.0.0/0"]
    security_group_ids     = [aws_security_group.cluster.id]
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy, aws_iam_role_policy_attachment.service_policy]

  tags = {
    Name = "${var.project_name}-${replace(var.region, "-", "")}-eks-cluster"
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_role_arn   = aws_iam_role.eks_node.arn
  node_group_name = var.node_group_name
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  instance_types = [var.instance_type]
  disk_size      = var.node_group_disk_size

  depends_on = [aws_eks_cluster.this]
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.container_name
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = var.container_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.container_name
        }
      }

      spec {
        container {
          name  = var.container_name
          image = var.container_image

          port {
            container_port = var.container_port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "${var.container_name}-svc"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    selector = {
      app = var.container_name
    }

    port {
      port        = 80
      target_port = var.container_port
      node_port   = var.node_port
    }

    type = "NodePort"
  }
}

data "aws_security_groups" "nodegroup" {
  filter {
    name   = "tag:Name"
    values = [local.node_group_sg_name]
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${replace(var.region, "-", "")}-alb-sg"
  description = "ALB security group for EKS application"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "${var.project_name}-${replace(var.region, "-", "")}-alb-sg"
  }
}

resource "aws_security_group_rule" "allow_alb_to_nodes" {
  type                     = "ingress"
  from_port                = var.node_port
  to_port                  = var.node_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = data.aws_security_groups.nodegroup.ids[0]
}

resource "aws_lb" "app" {
  name               = "${var.project_name}-${replace(var.region, "-", "")}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  idle_timeout       = 60

  tags = {
    Name = "${var.project_name}-${replace(var.region, "-", "")}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-${replace(var.region, "-", "")}-tg"
  port        = var.node_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-${replace(var.region, "-", "")}-tg"
  }
}

data "aws_autoscaling_group" "nodegroup_asgs" {
  for_each = toset(aws_eks_node_group.this.resources[0].autoscaling_groups[*].name)
  name     = each.key
}

resource "aws_lb_target_group_attachment" "node" {
  for_each = toset(flatten([for asg in aws_eks_node_group.this.resources[0].autoscaling_groups : data.aws_autoscaling_group.nodegroup_asgs[asg.name].instances[*].id]))

  target_group_arn = aws_lb_target_group.app.arn
  target_id        = each.key
  port             = var.node_port
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = var.enable_https ? 443 : 80
  protocol          = var.enable_https ? "HTTPS" : "HTTP"
  ssl_policy        = var.enable_https ? "ELBSecurityPolicy-2016-08" : null
  certificate_arn   = var.enable_https ? aws_acm_certificate_validation.cert[0].certificate_arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_acm_certificate" "certificate" {
  count              = var.enable_https ? 1 : 0
  domain_name        = var.app_domain
  validation_method  = "DNS"
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${replace(var.region, "-", "")}-certificate"
  }
}

resource "aws_route53_record" "certificate_validation" {
  count   = var.enable_https ? 1 : 0
  name    = aws_acm_certificate.certificate[0].domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.certificate[0].domain_validation_options[0].resource_record_type
  zone_id = var.hosted_zone_id
  records = [aws_acm_certificate.certificate[0].domain_validation_options[0].resource_record_value]
  ttl     = 300
}

resource "aws_acm_certificate_validation" "cert" {
  count                   = var.enable_https ? 1 : 0
  certificate_arn         = aws_acm_certificate.certificate[0].arn
  validation_record_fqdns = [aws_route53_record.certificate_validation[0].fqdn]
}

output "alb_dns_name" {
  description = "DNS name of the regional application load balancer."
  value       = aws_lb.app.dns_name
}

output "alb_zone_id" {
  description = "Zone ID for the regional ALB."
  value       = aws_lb.app.zone_id
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "node_security_group_id" {
  description = "Security group ID used by EKS worker nodes."
  value       = data.aws_security_groups.nodegroup.ids[0]
}
