#!/bin/bash

# Variables
ECR_REPOSITORY_URI="<aws_account_id>.dkr.ecr.<region>.amazonaws.com/my-app"
CONTAINER_NAME="my-app"

# Stop and remove any existing containers
docker stop $CONTAINER_NAME || true
docker rm $CONTAINER_NAME || true

# Log in to AWS ECR
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI

# Pull the latest image from ECR
docker pull $ECR_REPOSITORY_URI:latest

# Run the container
docker run -d --name $CONTAINER_NAME -p 80:5000 $ECR_REPOSITORY_URI:latest