data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

resource "random_id" "node_id" {
  byte_length = 2
  count       = var.instance_count
  keepers = {
    key_name = var.key_name
  }
}

resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = var.public_key
}

resource "aws_instance" "node" {
  count                  = var.instance_count
  instance_type          = var.instance_type
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.auth.id
  vpc_security_group_ids = var.public_sg
  subnet_id              = var.public_subnets[count.index]
  user_data = templatefile(var.user_data_path,
    {
      nodename   = "node-${random_id.node_id[count.index].dec}"
      dbuser     = var.dbuser
      dbpassword = var.dbpassword
      dbendpoint = var.dbendpoint
      dbname     = var.dbname
    }
  )
  root_block_device {
    volume_size = var.vol_size
  }
  tags = {
    Name                              = "node-${random_id.node_id[count.index].dec}"
    "kubernetes.io/cluster/mycluster" = "owned"
  }
}

resource "aws_alb_target_group_attachment" "tg_attach" {
  count            = var.enable_lb_tg_group_attachment ? var.instance_count : 0
  target_group_arn = var.lb_target_group_arn
  target_id        = aws_instance.node[count.index].id
  port             = var.tg_port
}

resource "null_resource" "kubeconfig" {
  count                  = var.instance_count
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.node[count.index].public_ip
      private_key = var.private_key
    }
    inline = ["echo 'hello'"]
  }
  provisioner "local-exec" {
    command = templatefile("${path.cwd}/files/scp_script.tpl",
      {
        nodeip           = aws_instance.node[count.index].public_ip
        k3s_path         = "${path.cwd}"
        nodename         = aws_instance.node[count.index].tags.Name
        private_key      = var.private_key
      }
    )
  }
}

data "local_file" "kubeconfig" {
    count                  = var.instance_count
    depends_on = [null_resource.kubeconfig]
    filename = "${path.cwd}/files/k3s-${aws_instance.node[count.index].tags.Name}.yaml"
}
