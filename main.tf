provider "aws" {
 region = "us-east-1"
}

resource "aws_instance" "example" {
 ami = "ami-03c7d01cf4dedc891"#ubuntu"ami-007855ac798b5175e"
 instance_type = "t2.micro"
 vpc_security_group_ids = [aws_security_group.instance.id]
 user_data = <<-EOF
 #!/bin/bash
 
 #Install Apache Web Server
 yum update -y
 yum install httpd -y
 sudo systemctl start httpd
 sudo systemctl enable httpd

 #Discover configuration using EC2 Metadata
 ID=$(curl 169.254.169.254/latest/meta-data/instance-id)
 TYPE=$(curl 169.254.169.254/latest/meta-data/instance-type)
 AZ=$(curl 169.254.169.254/latest/meta-data/placement/availability-zone)
 IPV4=$(curl 169.254.169.254/latest/meta-data/public-ipv4)

 #Set up website
 cd  /var/www/html

 #Generate home page
 echo "<html><body><H1>Welcome to your EC2 Instance</H1><p><p>" > ./index.html
 echo "This is a <strong>$TYPE</strong> instance" >> ./index.html
 echo "in <strong>$AZ</strong>" >> ./index.html
 if ["$IPV4"];
 then
     echo "The public IP is <strong>$IPV4</strong>.<p><p></body></html> >> ./index.html
 else
     echo "This instance does <strong>NOT</strong> have" >> ./index.html
     echo "a public IP address.<p><p></body></html>" >> ./index.html
 fi
 
 EOF
 user_data_replace_on_change = true
 tags = {
 Name = "terraform-example"
 }
}

resource "aws_security_group" "instance" {
 name = "terraform-example-instance"
 
 ingress {
   from_port = 80
   to_port = 80
   protocol = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }
#allows ping
 ingress {
   from_port = -1
   to_port = -1
   protocol = "icmp"
   cidr_blocks = ["0.0.0.0/0"]
 }
 
 egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

output "ec2_global_ips" {
  value = ["${aws_instance.example.public_ip}"]
}