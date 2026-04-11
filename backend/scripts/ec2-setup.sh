#!/bin/bash
# EC2 анхны тохиргоо — нэг л удаа ажиллуулна
# Шаардлага: Amazon Linux 2023 эсвэл Ubuntu 22.04

set -e

AWS_REGION="ap-northeast-1"

echo "=== 1. Docker суулгах ==="
if ! command -v docker &> /dev/null; then
  # Amazon Linux 2023
  if command -v dnf &> /dev/null; then
    sudo dnf install -y docker
  # Ubuntu
  else
    sudo apt-get update -y
    sudo apt-get install -y docker.io
  fi
  sudo systemctl enable --now docker
  sudo usermod -aG docker $USER
  echo "Docker суулгагдлаа. Дахин нэвтэрнэ үү: 'exit' → ssh дахин"
else
  echo "Docker аль хэдийн байна: $(docker --version)"
fi

echo ""
echo "=== 2. AWS CLI суулгах ==="
if ! command -v aws &> /dev/null; then
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp
  sudo /tmp/aws/install
  rm -rf /tmp/awscliv2.zip /tmp/aws
  echo "AWS CLI суулгагдлаа: $(aws --version)"
else
  echo "AWS CLI аль хэдийн байна: $(aws --version)"
fi

echo ""
echo "=== 3. .env файл үүсгэх ==="
mkdir -p ~/backend
ENV_FILE=~/backend/.env

if [ ! -f "$ENV_FILE" ]; then
  cat > "$ENV_FILE" << 'ENVEOF'
PORT=3000
GROQ_API_KEY=gsk_REPLACE_ME
FIREBASE_SERVICE_ACCOUNT={"REPLACE":"ME"}
ENVEOF
  echo ".env үүслээ: $ENV_FILE"
  echo "АНХААРУУЛГА: Бодит утгуудыг оруулна уу!"
  echo "  nano ~/backend/.env"
else
  echo ".env аль хэдийн байна: $ENV_FILE"
fi

echo ""
echo "=== 4. ECR нэвтрэлт шалгах ==="
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ -n "$ACCOUNT_ID" ]; then
  ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
  echo "AWS Account: $ACCOUNT_ID"
  echo "ECR Registry: $ECR_REGISTRY"

  # ECR нэвтрэх тест
  aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $ECR_REGISTRY && \
    echo "ECR нэвтрэлт амжилттай" || \
    echo "ECR нэвтрэлт амжилтгүй — EC2 IAM role шалгана уу"
else
  echo "AWS нэвтрэлт олдсонгүй — EC2 IAM role тохируулсан эсэхийг шалгана уу"
fi

echo ""
echo "================================================"
echo "Тохиргоо дууслаа!"
echo ""
echo "Дараагийн алхам:"
echo "  1. nano ~/backend/.env   # API key-үүдийг оруулах"
echo "  2. GitHub → Settings → Secrets тохируулах (доорх)"
echo ""
echo "GitHub Secrets:"
echo "  AWS_ACCESS_KEY_ID     = AWS IAM user-н access key"
echo "  AWS_SECRET_ACCESS_KEY = AWS IAM user-н secret key"
echo "  EC2_HOST              = $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'EC2-н public IP')"
echo "  EC2_SSH_KEY           = .pem файлын агуулга (cat your-key.pem)"
echo "================================================"
