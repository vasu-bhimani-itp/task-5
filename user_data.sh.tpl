#!/bin/bash
set -e

# ===== Variables injected by Terraform =====
AWS_REGION="${aws_region}"
ACCOUNT_ID="${account_id}"
REPO_NAME="${repo_name}"
IMAGE_TAG="${image_tag}"   # optional

ECR_URL="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

LOG_FILE="/var/log/user-data.log"
exec > >(tee -a $LOG_FILE) 2>&1

echo "===== Starting EC2 bootstrap ====="

# ===== System Update =====
yum update -y

# ===== Install Docker =====
amazon-linux-extras install docker -y || yum install docker -y
systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

# ===== Install AWS CLI v2 =====
if ! command -v aws &> /dev/null
then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
fi

# ===== Login to ECR using IAM Role =====
echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION \
| docker login --username AWS --password-stdin $ECR_URL

# ===== Determine Image Tag =====
if [ -z "$IMAGE_TAG" ] || [ "$IMAGE_TAG" = "latest-by-time" ]; then
    echo "Fetching latest image tag from ECR..."

    IMAGE_TAG=$(aws ecr describe-images \
      --repository-name $REPO_NAME \
      --region $AWS_REGION \
      --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' \
      --output text)

    if [ "$IMAGE_TAG" = "None" ] || [ -z "$IMAGE_TAG" ]; then
        echo "ERROR: No image tag found in ECR!"
        exit 1
    fi

    echo "Latest image tag: $IMAGE_TAG"
else
    echo "Using provided image tag: $IMAGE_TAG"
fi

IMAGE_URI="${ECR_URL}/${REPO_NAME}:${IMAGE_TAG}"
echo "Final image URI: $IMAGE_URI"

# ===== Pull Image =====
docker pull $IMAGE_URI

# ===== Replace old container =====
docker rm -f my-app || true

# ===== Run Container =====
docker run -d \
  --name my-app \
  -p 80:5000 \
  --restart always \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  $IMAGE_URI

echo "===== Deployment completed successfully ====="