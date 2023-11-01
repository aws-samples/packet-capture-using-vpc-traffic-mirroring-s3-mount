#! /bin/bash

sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd

echo "<h1>Deployed for Packet Captures demo</h1>" | sudo tee /var/www/html/index.html