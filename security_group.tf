# Security Group for EKS Cluster Control Plane
resource "aws_security_group" "eks_security_group" {
  name        = "eks-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow outbound communication to anywhere
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-cluster-sg"
  }
}

# Security Group for EKS Node Group
resource "aws_security_group" "node_security_group" {
  name        = "eks-node-group-sg"
  description = "EKS node group security group"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow outbound communication to anywhere
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-node-group-sg"
  }
}

# Add Ingress Rule to Allow Node-to-Cluster Traffic
resource "aws_security_group_rule" "node_to_cluster" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_security_group.id
  source_security_group_id = aws_security_group.node_security_group.id
}

# Add Ingress Rule to Allow Cluster-to-Node Traffic
resource "aws_security_group_rule" "cluster_to_node" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.node_security_group.id
  source_security_group_id = aws_security_group.eks_security_group.id
}

# Add Self-Ingress Rule for Node Group
resource "aws_security_group_rule" "node_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.node_security_group.id
  self              = true
}
