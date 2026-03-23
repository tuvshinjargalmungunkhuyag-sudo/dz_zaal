#!/bin/bash
set -e

AWS="/c/Program Files/Amazon/AWSCLIV2/aws"
ECR="250037328509.dkr.ecr.ap-northeast-1.amazonaws.com"
EC2="ec2-user@13.112.91.27"
KEY="$HOME/.ssh/dz-zaal-key.pem"

echo "=== 1. ECR login ==="
"$AWS" ecr get-login-password --region ap-northeast-1 | \
  docker login --username AWS --password-stdin $ECR

echo "=== 2. Local build ==="
docker build -t dz-zaal-backend .
docker tag dz-zaal-backend:latest $ECR/dz-zaal-backend:latest

echo "=== 3. ECR push ==="
docker push $ECR/dz-zaal-backend:latest

echo "=== 4. EC2 deploy ==="
ssh -i $KEY -o StrictHostKeyChecking=no $EC2 "
  aws ecr get-login-password --region ap-northeast-1 | \
    docker login --username AWS --password-stdin $ECR
  docker pull $ECR/dz-zaal-backend:latest
  docker stop dz-zaal-backend || true
  docker rm dz-zaal-backend || true
  docker run -d \
    --name dz-zaal-backend \
    --restart unless-stopped \
    --env-file ~/backend/.env \
    -p 3000:3000 \
    $ECR/dz-zaal-backend:latest
"

echo "=== Deploy амжилттай! ==="
