data "aws_ami" "server_ami" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "random_id" "maze_node_id" {
  byte_length = 2
  count       = var.main_instance_count
}

resource "aws_key_pair" "maze_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "maze_main" {
  count                  = var.main_instance_count
  instance_type          = var.main_instance_type
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.maze_auth.id
  vpc_security_group_ids = [aws_security_group.maze_sg.id]
  subnet_id              = aws_subnet.maze_public_subnet.*.id[count.index]
  user_data              = templatefile("./main-userdata.tpl", { new_hostname = "maze-main-${random_id.maze_node_id[count.index].dec}" })
  root_block_device {
    volume_size = var.main_vol_size
  }

  tags = {
    Name = "maze-main-${random_id.maze_node_id[count.index].dec}"
  }

#   provisioner "local-exec" {
#     command = "printf '\n${self.public_ip}' >> aws_hosts"
#   }

#   provisioner "local-exec" {
#     when    = destroy
#     command = "sed -i '/^[0-9]/d' aws_hosts"
#   }
# }

# resource "null_resource" "httpd_update" {
#   count = var.main_instance_count
#   provisioner "remote-exec" {
#     inline = ["sudo yum upgrade -y httpd && touch upgrade.log && echo 'I updated HTTPD' >> upgrade.log"]

#     connection {
#       type        = "ssh"
#       user        = "Ubuntu"
#       private_key = file("/home/ubuntu/.ssh/1mazeKey")
#       timeout     = "2m"
#       host        = aws_instance.maze_main[count.index].public_ip
#       agent       = false
#     }
#   }
}