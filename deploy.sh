#!/bin/bash
# ===========================================
# DevSecOps Capstone Deployment Script
# Author: Mubarak Usman Shehu
# ===========================================

set -e  # Stop the script on any error

# Stage 1: Collect and validate user input
echo "🚀 Starting automated deployment setup..."
read -p "🔗 Enter your GitHub repository URL: " REPO_URL
read -s -p "🔑 Enter your GitHub Personal Access Token: " PAT
echo ""
read -p "🌿 Enter branch name [default: main]: " BRANCH
BRANCH=${BRANCH:-main}
read -p "🌍 Enter remote server IP: " SERVER_IP
read -p "👤 Enter SSH username: " SSH_USER
read -p "📁 Enter deployment directory on server (e.g., /var/www/app): " DEPLOY_DIR

# Stage 2: Clone repository
echo "📦 Cloning repository..."
if [ -d "./repo" ]; then
    echo "🔁 Repo folder exists. Pulling latest changes..."
    cd repo && git pull origin $BRANCH && cd ..
else
    git clone -b $BRANCH https://${PAT}@${REPO_URL#https://} repo
fi

cd repo

# Stage 3: Build Docker image
echo "🐳 Building Docker image..."
docker build -t capstone-app .

# Stage 4: Security scan using Trivy
echo "🛡️ Running Trivy vulnerability scan..."
trivy image capstone-app || echo "⚠️ Trivy scan completed with warnings."

# Stage 5: Deploy to remote server
echo "🚀 Deploying to remote server..."
scp -r . $SSH_USER@$SERVER_IP:$DEPLOY_DIR
ssh $SSH_USER@$SERVER_IP <<EOF
  cd $DEPLOY_DIR
  docker stop capstone-app || true
  docker rm capstone-app || true
  docker run -d --name capstone-app -p 80:80 capstone-app
EOF

# Stage 6: Completion message
echo "✅ Deployment completed successfully!"
