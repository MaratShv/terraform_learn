provider "aws" {
    region = "us-east-2"
}

variable "server_port" {
    description = "the port the server will use for HTTP requests"
    type = number
    default = 8080  
}

#output "public_ip" {
#    value = aws_instance.example.public_ip
#    description = "The public IP address of the my web server"  
#}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
    filter {
      name = "vpc-id"
      values = [data.aws_vpc.default.id]
    }
    #vpc_id = data.aws_vpc.default.id
}

resource "aws_launch_configuration" "example" {
    image_id = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hellow, World!" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
    #ukazivaem 4tob sna4ala razvernulos' novoe a porom udalilos' staroe
    lifecycle {
      create_before_destroy = true
    }

}

resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name
    vpc_zone_identifier = data.aws_subnets.default.ids

    min_size = 2
    max_size = 10

    tag {
      key = "Name"
      value = "terraform-asg-example"
      propagate_at_launch = true
    }  
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
