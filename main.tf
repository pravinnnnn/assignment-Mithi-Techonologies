provider "aws" {

  region                   = ap-south-1
  shared_credentials_files = ["C:/Users/navi/.aws/credentials"]

}

resource "aws_vpc" "Wp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "Wp_vpc1"
  }

}

resource "aws_subnet" "Wp_vpc_pbsubnet" {
  vpc_id                  = aws_vpc.Wp_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    "Name" = "Wp_public"
  }
}

resource "aws_internet_gateway" "Wp_internet_gateway" {
  vpc_id = aws_vpc.Wp_vpc.id

  tags = {
    "Name" = "Wp_igw"
  }
}

resource "aws_route_table" "_public_rt" {
  vpc_id = aws_vpc.Wp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Wp_internet_gateway.id
  }

  tags = {
    "Name" = "Wp_public_rt1"
  }

}

resource "aws_route_table_association" "Wp_public_rt-asso" {
  subnet_id      = aws_subnet.Wp_vpc_pbsubnet.id
  route_table_id = aws_route_table.Wp_public_rt.id
}




resource "aws_security_group" "Wp_sg" {
  name        = "Wp_sg1"
  description = "Wp sequrity group"
  vpc_id      = aws_vpc.Wp_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "Wp_sg1"
  }

}

resource "aws_instance" "Wp_nginx-wordpress-instance" {
  ami                    = "ami-07d3a50bd29811cd1"
  instance_type          = "t2.micro"
  key_name               = "zoro"
  vpc_security_group_ids = ["sg-090ef897b903569df"]
  subnet_id              = aws_subnet.Wp_vpc_pbsubnet.id

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx",
      "sudo apt-get install -y mysql-server",
      "sudo mysql_secure_installation",
      "sudo apt-get install -y php-fpm php-mysql",
      "sudo sed -i 's/index index.html/index index.php index.html/g' /etc/nginx/sites-available/default",
      "sudo sed -i 's/#location ~ \\.php$ {/location ~ \\.php$ {/g' /etc/nginx/sites-available/default",
      "sudo sed -i 's/#\tinclude snippets/fastcgi-php.conf;/g' /etc/nginx/sites-available/default",
      "sudo sed -i 's/#\tfastcgi_pass unix/fastcgi_pass unix/g' /etc/nginx/sites-available/default",
      "sudo sed -i 's/#}/}/g' /etc/nginx/sites-available/default",
      "sudo systemctl restart nginx",
      "sudo mysql -e \"CREATE DATABASE wordpress;\"",
      "sudo mysql -e \"GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost' IDENTIFIED BY 'password';\"",
      "sudo mysql -e \"FLUSH PRIVILEGES;\""
    ]
    
  }

  tags = {
    "Name" = "nginx-wordpress-instance"
  }

  root_block_device {
    volume_size = 20
  }
}

resource "aws_eip" "Wp_pb_eip" {
  instance = aws_instance.Wp_nginx-wordpress-instance.id
  vpc      = true

}



