#!/bin/bash

set -e

echo "🚀 Setting up ThinkStack Blog Platform..."
echo "==========================================="

# --- Update system ---
sudo apt update && sudo apt upgrade -y

# --- Install required packages ---
echo "📦 Installing dependencies..."
sudo apt install -y curl git nginx postgresql postgresql-contrib

# --- Install Node.js 20 ---
echo "📦 Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# --- Install PM2 ---
echo "📦 Installing PM2..."
sudo npm install -g pm2

# --- Configure PostgreSQL ---
echo "🗄️ Configuring PostgreSQL..."
sudo -u postgres psql <<EOF
ALTER USER postgres PASSWORD 'shree@2205';
CREATE DATABASE "ThinkStack";
EOF

echo "✅ PostgreSQL ready"

# --- Setup project directory ---
echo "📁 Setting up project directory..."
sudo mkdir -p /var/www/ThinkStack
sudo chown -R $USER:$USER /var/www/ThinkStack

cd /var/www/ThinkStack

# --- Clone repo ---
echo "📥 Cloning repository..."
git clone https://github.com/ShreenandBandre/ThinkStack.git .

# --- Create .env ---
echo "⚙️ Creating backend .env..."

cat <<EOT > backend/.env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=shree@2205
DB_NAME=ThinkStack
PORT=5000
EOT

# --- Install backend ---
echo "📦 Installing backend..."
cd backend
npm install --production

# --- Build frontend ---
echo "🔨 Building frontend..."
cd ../frontend
npm install
npm run build

# --- Configure Nginx ---
echo "🌐 Configuring Nginx..."

sudo cp /var/www/ThinkStack/deploy/ThinkStack-nginx.conf /etc/nginx/sites-available/thinkstack

sudo ln -sf /etc/nginx/sites-available/thinkstack /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# --- Start backend ---
echo "🚀 Starting backend with PM2..."
cd /var/www/ThinkStack/backend

pm2 start src/index.js --name thinkstack
pm2 save
pm2 startup systemd -u $USER --hp /home/$USER | tail -1 | sudo bash

# --- Final output ---
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo ""
echo "==========================================="
echo "🎉 ThinkStack is LIVE!"
echo "==========================================="
echo "🌐 http://$PUBLIC_IP"
echo ""

echo "Useful commands:"
echo "pm2 status"
echo "pm2 logs"
echo "pm2 restart all"
echo "sudo systemctl restart nginx"