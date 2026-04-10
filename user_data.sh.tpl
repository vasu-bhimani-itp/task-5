#!/bin/bash
set -e


AWS_REGION="${aws_region}"
ACCOUNT_ID="${account_id}"
REPO_NAME="${repo_name}"
IMAGE_TAG=""  

ECR_URL="$${ACCOUNT_ID}.dkr.ecr.$${AWS_REGION}.amazonaws.com"

LOG_FILE="/var/log/user-data.log"
exec > >(tee -a $LOG_FILE) 2>&1

echo "===== Starting EC2 bootstrap ====="

yum update -y


amazon-linux-extras install docker -y || yum install docker -y
systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

if ! command -v aws &> /dev/null
then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
fi


echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION \
| docker login --username AWS --password-stdin $ECR_URL

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

IMAGE_URI="$${ECR_URL}/$${REPO_NAME}:$${IMAGE_TAG}"
echo "Final image URI: $IMAGE_URI"

docker pull $IMAGE_URI

docker rm -f my-app || true

docker run -d \
  --name my-app \
  -p 80:5000 \
  --restart always \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  $IMAGE_URI

echo "===== Deployment completed successfully ====="