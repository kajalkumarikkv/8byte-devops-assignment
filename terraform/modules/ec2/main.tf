resource "aws_instance" "sample" {
  ami           = "ami-07ff62358b87c7116"
  instance_type = var.instance_type

  subnet_id = var.subnet_id

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  user_data_replace_on_change = true

  user_data = <<-EOF
  #!/bin/bash
  # bootstrap-version-2
  dnf update -y
  dnf install -y nginx

  systemctl enable nginx
  systemctl start nginx

  echo "Hello from Terraform EC2" > /usr/share/nginx/html/index.html
EOF
}