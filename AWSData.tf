provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

data "aws_vpc" "selected" {
  filter {
    name = "tag:Name"
    values = ["*tfvrf1*"]
  }
}

data "aws_subnet" "mySubnet" {
  filter {
    name = "tag:Name"
    values = ["*20.0.1.0*"]
  }
}

resource "aws_network_interface" "ubuntu" {
  subnet_id   = data.aws_subnet.mySubnet.id
  private_ips = ["20.0.1.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

data "template_file" "user_data" {
  template = file("cloudinit-client-aws.conf")
}

resource "aws_eip" "ubuntu" {
  #instance = aws_instance.ubuntu.id
}

resource "aws_instance" "ubuntu" {
  key_name      = "domFrankfurt"
  ami           = "ami-0b1deee75235aa4bb"
  instance_type = "t2.micro"
  user_data     = data.template_file.user_data.rendered

  tags = {
    Name = "ubuntu",
    application = "db"
  }

  network_interface {
    network_interface_id = aws_network_interface.ubuntu.id
    device_index         = 0
  }

  connection {
    type        = "ssh"
    user        = "cisco"
    private_key = file("key")
    host = "${aws_eip.ubuntu.public_ip}"
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir /home/cisco/templates",
      "sudo chown cisco /home/cisco/templates",
      "sudo chgrp cisco /home/cisco/templates"
    ]
  }
  provisioner "file" {
    source      = "cloudACI/AZURE/app.py"
    destination = "/home/cisco/app.py"
  }
  provisioner "file" {
    source      = "templates/index.html"
    destination = "/home/cisco/templates/index.html"
  }
  provisioner "file" {
    source      = "templates/showdog.html"
    destination = "/home/cisco/templates/showdog.html"
  }
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 30
  }
}


resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.ubuntu.id
  allocation_id = aws_eip.ubuntu.id
}
