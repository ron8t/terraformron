#!/bin/bash

# Update the package repository and install necessary dependencies
sudo yum update -y
sudo yum install -y wget unzip

# Install Amazon Corretto 17 (Java 17)
sudo yum install -y java-17-amazon-corretto-devel

# Install Maven 3.9.6
LATEST_MAVEN_VERSION=3.9.6
wget https://dlcdn.apache.org/maven/maven-3/${LATEST_MAVEN_VERSION}/binaries/apache-maven-${LATEST_MAVEN_VERSION}-bin.zip
unzip -o apache-maven-${LATEST_MAVEN_VERSION}-bin.zip -d /opt
sudo ln -sfn /opt/apache-maven-${LATEST_MAVEN_VERSION} /opt/maven

# Set up Maven environment variables globally
echo 'export M2_HOME=/opt/maven' | sudo tee -a /etc/profile.d/maven.sh
echo 'export PATH=$M2_HOME/bin:$PATH' | sudo tee -a /etc/profile.d/maven.sh

# Add environment variables for root user
echo 'export M2_HOME=/opt/maven' | sudo tee -a /root/.bashrc
echo 'export PATH=$M2_HOME/bin:$PATH' | sudo tee -a /root/.bashrc

# Source the profile script to load the new environment variables
source /etc/profile.d/maven.sh

# Verify Maven installation
echo "Verifying Maven installation..."
/opt/maven/bin/mvn -version

# Download and install SonarQube 10.5.1.90531
SONARQUBE_VERSION=10.5.1.90531
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip
if [ $? -ne 0 ]; then
    echo "Failed to download SonarQube. Exiting."
    exit 1
fi

unzip -o sonarqube-${SONARQUBE_VERSION}.zip -d /opt
sudo mv /opt/sonarqube-${SONARQUBE_VERSION} /opt/sonarqube

# Ensure the binaries have executable permissions
sudo chmod +x /opt/maven/bin/mvn
sudo chmod +x /opt/sonarqube/bin/linux-x86-64/sonar.sh

# Create sonarqube group and user if not exists
if ! getent group sonarqube > /dev/null; then
    sudo groupadd sonarqube
fi

if ! id -u sonarqube > /dev/null 2>&1; then
    sudo useradd -g sonarqube sonarqube
fi

sudo chown -R sonarqube:sonarqube /opt/sonarqube

# Configure SonarQube to use PostgreSQL
sudo bash -c "cat <<EOF > /opt/sonarqube/conf/sonar.properties
sonar.jdbc.username=${var.db_username}
sonar.jdbc.password=${var.db_password}
sonar.jdbc.url=jdbc:postgresql://${aws_db_instance.postgresql.endpoint}/${var.db_name}
EOF"

# Set up SonarQube as a service
echo -e "[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/sonarqube.service

# Reload systemd and start SonarQube service
sudo systemctl daemon-reload
sudo systemctl enable sonarqube.service
sudo systemctl start sonarqube.service

# Check the status of the SonarQube service
sudo systemctl status sonarqube.service
