#! /bin/bash
sudo apt-get update -y
sudo apt install apache2 -y
sudo systemctl start apache2
sudo chown ubuntu:ubuntu -R /var/www
sudo echo "<h1>Hola mundo!<h1>" > /var/www/html/index.html
sudo hostname >> /var/www/html/index.html


# sudo apt-get update -y
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
# apt-cache policy docker-ce
# sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
# sudo addgroup docker
# sudo usermod -aG docker $USER
# sudo chmod 666 /var/run/docker.sock
# newgrp docker
# sudo systemctl restart docker.service
# docker run --name mynginx1 -p 80:80 -d nginx






  