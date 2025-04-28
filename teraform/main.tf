provider "aws" {
  region = "us-east-1"  # Change the region as per your requirement
}

resource "aws_security_group" "sonarqube_sg" {
  name        = "sonarqube-sg"
  description = "Security group for SonarQube instance"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


resource "aws_instance" "sonarqube" {
  ami           = "ami-0abcdef1234567890"  # Replace with the latest Ubuntu or preferred image
  instance_type = "t3.medium"  # Adjust the instance type as per your needs

  security_groups = [aws_security_group.sonarqube_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              # Install dependencies
              sudo apt update
              sudo apt install -y openjdk-11-jdk wget
              
              # Install SonarQube
              sudo useradd -m sonar
              cd /opt
              sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.8.0.57625.zip
              sudo unzip sonarqube-9.8.0.57625.zip
              sudo mv sonarqube-9.8.0.57625 sonarqube
              sudo chown -R sonar:sonar /opt/sonarqube
              sudo chmod -R 775 /opt/sonarqube
              
              # Create SonarQube service
              echo "[Unit]
              Description=SonarQube
              After=network.target
              
              [Service]
              Type=simple
              User=sonar
              ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
              ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
              Restart=always
              
              [Install]
              WantedBy=multi-user.target" | sudo tee /etc/systemd/system/sonarqube.service

              # Start SonarQube service
              sudo systemctl enable sonarqube
              sudo systemctl start sonarqube
              EOF

  tags = {
    Name = "SonarQubeInstance"
  }
}

output "sonarqube_url" {
  value = "http://${aws_instance.sonarqube.public_ip}:9000"
}
