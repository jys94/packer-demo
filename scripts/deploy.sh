#!/bin/bash
curl -fsSL https://rpm.nodesource.com/setup_14.x | sudo bash -
yum install -y nodejs
amazon-linux-extras install -y nginx1
systemctl enable --now nginx

groupadd node-demo
useradd -d /app -s /bin/false -g node-demo node-demo

mv /tmp/app /app
chown -R node-demo:node-demo /app

echo 'worker_processes auto;
pid /run/nginx.pid;

events {
        worker_connections 768;
        # multi_accept on;
}

http {
  server {
    listen 80;
    location / {
      proxy_pass http://localhost:3000/;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
  }
}' > /etc/nginx/nginx.conf

systemctl restart nginx

cd /app/app
npm install

echo '[Service]
ExecStart=/usr/bin/node /app/app/index.js
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=node-demo
User=node-demo
Group=node-demo
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/node-demo.service

systemctl enable node-demo
systemctl start node-demo
