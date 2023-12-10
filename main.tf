resource "aws_security_group" "my_sg" {
    description = "my security group"
    name = "my_eg"

    ingress = [
        {
            description = "ssh"
            from_port = 22
            to_port = 22
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
            ipv6_cidr_blocks = []
            prefix_list_ids = []
            security_groups = []
            self = false
        },
        {
            description = "elastic"
            from_port = 9200
            to_port = 9200
            protocol = "tcp"
            cidr_blocks = ["myip"]
            ipv6_cidr_blocks = []
            prefix_list_ids = []
            security_groups = []
            self = false
        },
        {
            description = "kibana"
            from_port = 5601
            to_port = 5601
            protocol = "tcp"
            cidr_blocks = ["myip"]
            ipv6_cidr_blocks = []
            prefix_list_ids = []
            security_groups = []
            self = false
        }
    ]

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
  }

}



resource "aws_instance" "linux-1" {
  ami           = "ami-0302f42a44bf53a45"
  instance_type = "t2.micro"
  key_name = "mykey"
  security_groups = [aws_security_group.my_sg.name]
}


data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "example" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["es:*"]
    resources = ["arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/aws-free-es-cluster/*"]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["myip"]
    }
  }
}

resource "aws_opensearch_domain" "aws_free_elasticsearch_cluster" {
  domain_name    = "aws-free-es-cluster"
  engine_version = "Elasticsearch_7.10"

  cluster_config {
    instance_type = "t3.small.search"
    instance_count = 2
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
    volume_type = "gp2"
  }

  access_policies = data.aws_iam_policy_document.example.json

  tags = {
    Domain = "aws_free_elasticsearch_cluster"
  }

}