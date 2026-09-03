########################
# EC2 Instance
########################

# Get the latest Ubuntu 24.04 LTS (Noble Numbat) AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Define EC2 instance for ControlPlane
resource "aws_instance" "control_plane" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.large"
  vpc_security_group_ids = [var.network.security_group_for_control_plane_id]
  subnet_id              = var.network.private_subnet_for_control_plane_id
  root_block_device {
    volume_type = "gp3"
    volume_size = "30"
    encrypted   = true
    tags = {
      Name = "${var.common.env}-ebs-control-plane${var.name_suffix}"
    }
  }
  iam_instance_profile = aws_iam_instance_profile.main.name
  tags = {
    Name = "${var.common.env}-ec2-control-plane${var.name_suffix}"
  }
}

# Define EC2 instance for WorkerNode
resource "aws_instance" "worker_node" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.large"
  vpc_security_group_ids = [var.network.security_group_for_worker_node_id]
  subnet_id              = var.network.private_subnet_for_worker_node_id
  root_block_device {
    volume_type = "gp3"
    volume_size = "30"
    encrypted   = true
    tags = {
      Name = "${var.common.env}-ebs-worker-node${var.name_suffix}"
    }
  }
  iam_instance_profile = aws_iam_instance_profile.main.name
  tags = {
    Name = "${var.common.env}-ec2-worker-node${var.name_suffix}"
  }
}

# Define IAM instance profile for EC2
resource "aws_iam_instance_profile" "main" {
  name = "${var.common.env}-instance-profile${var.name_suffix}"
  role = aws_iam_role.main.name
}

resource "aws_iam_role" "main" {
  name               = "${var.common.env}-role-for-ec2${var.name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.main.json
}

data "aws_iam_policy_document" "main" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "main" {
  for_each = {
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  role       = aws_iam_role.main.name
  policy_arn = each.value
}