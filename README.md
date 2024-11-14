# Fully Automated AWS CI/CD Pipeline for Python Applications

This guide will walk you through the process of building a fully automated CI/CD pipeline for Python applications using **AWS CodeCommit**, **AWS CodeBuild**, **Amazon ECR**, **AWS CodeDeploy**, **AWS EC2**, and **AWS Secrets Manager**. The pipeline automates the deployment of your Python application, ensuring faster and more reliable delivery to your UAT to PROD environment.

## Overview of Services Used

- **AWS CodeCommit**: A fully managed source control service that hosts Git repositories.
- **Amazon Elastic Container Registry (ECR)**: A container image repository service that stores Docker images.
- **AWS Secrets Manager**: A service to securely store and manage secrets, such as database credentials, API keys, etc.
- **AWS CodeBuild**: A fully managed build service that compiles source code, runs tests, and produces artifacts for deployment.
- **AWS CodeDeploy**: A fully managed deployment service that automates the application deployment to EC2 instances.
- **AWS CodePipeline**: A CI/CD service that automates the build, test, and deployment of applications.
- **AWS EC2**: Compute instances that will host the deployed containerized Python application.
- **AWS IAM**: Permissions and security roles to manage access to the AWS services.

---

## UAT Deployment Flow

The flow for **UAT (User Acceptance Testing)** deployment is as follows:

1. **CodeCommit** stores the source code.
2. **CodePipeline** automatically triggers the build process in **CodeBuild** when changes are pushed to CodeCommit.
3. **CodeBuild** builds the Docker image of the Python application and pushes it to **ECR**.
4. **CodeDeploy** deploys the Docker container from **ECR** to EC2 instances tagged as `Environment=uat`.
5. EC2 instances, tagged as `Environment=uat`, will run the deployed containerized application.

---

## Prerequisites

Before setting up the CI/CD pipeline, ensure the following prerequisites are met:

1. **EC2 Instances for UAT**: You need EC2 instances with the tag `Environment=uat` where the application will be deployed.
2. **Python Flask App**: A simple Python Flask app that can be containerized for deployment. Ensure your application has a `Dockerfile` and necessary configurations.
3. **IAM Roles and Policies**: Proper IAM roles and policies for **CodePipeline**, **CodeBuild**, and **CodeDeploy** to access necessary resources, including **Secrets Manager**.
4. **AWS Secrets Manager**: Used to securely store secrets, such as database credentials and API keys, that will be accessed by the application during the build and deployment.

---

## Setting Up the AWS CI/CD Pipeline

### **1. AWS CodeCommit (Source Control)**

**Steps**:
- **Create a repository** in **AWS CodeCommit** to store your Python application's source code.
- **Push your application code** to **CodeCommit** via Git.
- **CodePipeline** will monitor this repository for changes.

**IAM Role and Policy** for CodeCommit:
- The **developer** or **user** pushing code needs the **CodeCommit** policy.
- The **CodePipeline service role** needs permissions to pull the code from CodeCommit.

**IAM Policy for Developer/User** (to push code):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:GitPull",
        "codecommit:GitPush",
        "codecommit:CreateRepository",
        "codecommit:ListRepositories",
        "codecommit:DescribeRepository"
      ],
      "Resource": "*"
    }
  ]
}
```

**IAM Policy for CodePipeline** (to pull code from CodeCommit):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:GitPull"
      ],
      "Resource": "*"
    }
  ]
}
```

### **2. Amazon Elastic Container Registry (ECR)**

**Steps**:
- **Create a repository** in **ECR** to store Docker images.
- **CodeBuild** will build the Docker image and push it to **ECR**.

**IAM Role and Policy** for ECR:
- **CodeBuild** needs permissions to push Docker images to **ECR**.
- **CodePipeline** also needs access to **ECR**.

**IAM Policy for CodeBuild** (to push Docker images to ECR):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:BatchGetImage",
        "ecr:DescribeRepositories",
        "ecr:CreateRepository"
      ],
      "Resource": "arn:aws:ecr:region:account-id:repository/repository-name"
    }
  ]
}
```

**IAM Policy for CodePipeline** (to interact with ECR):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:BatchGetImage"
      ],
      "Resource": "arn:aws:ecr:region:account-id:repository/repository-name"
    }
  ]
}
```
### **3. AWS Secrets Manager**

**Steps**:
- Store sensitive information such as **database credentials**, **API keys**, or **configuration values** in **AWS Secrets Manager**.
- **CodeBuild** and **CodeDeploy** need to access these secrets securely.

**IAM Role and Policy** for Secrets Manager:
- **CodeBuild**, **CodeDeploy**, and **CodePipeline** need permissions to **get secrets** from **Secrets Manager**.

**IAM Policy for CodeBuild/CodeDeploy/CodePipeline** (to retrieve secrets):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:region:account-id:secret:secret-id"
    }
  ]
}
```

---

### **4. AWS CodeBuild (Build Service)**

**Steps**:
- **Create a build project** in **AWS CodeBuild**.
- **Configure the `buildspec.yml` file** to define the steps for building the Docker image and pushing it to **ECR**.
- **CodePipeline** will trigger **CodeBuild** whenever changes are pushed to **CodeCommit**.

**IAM Role and Policy** for CodeBuild:
- **CodeBuild** requires permissions to access **CodeCommit** (for source code), **ECR** (for Docker image storage), **Secrets Manager** (to access secrets), and **CloudWatch Logs** (for logging).

**IAM Policy for CodeBuild**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:Get*",
        "codecommit:List*",
        "codecommit:DescribeRepository",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "secretsmanager:GetSecretValue",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### **5. AWS CodeDeploy (Deployment Service)**

**Steps**:
- **Create an application** in **AWS CodeDeploy** for deploying the Docker container to **EC2 instances**.
- **Create a deployment group** for **UAT** and **Production** environments.
- **CodePipeline** will trigger **CodeDeploy** to deploy the Docker image from **ECR** to **EC2**.

**IAM Role and Policy** for CodeDeploy:
- **CodeDeploy** needs permissions to interact with **EC2** instances and deploy the Docker container from **ECR**.

**IAM Policy for CodeDeploy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentConfig",
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:CreateDeploymentGroup",
        "codedeploy:ListDeployments"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeTags",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### **6. AWS CodePipeline (CI/CD Service)**

**Steps**:
- **Create a pipeline** in **AWS CodePipeline** to automate the build and deployment process.
- The pipeline will connect to **CodeCommit** (for source code), **CodeBuild** (for build process), **ECR** (for Docker images), and **CodeDeploy** (for deployment).

**IAM Role and Policy** for CodePipeline:
- **CodePipeline** needs permissions to interact with **CodeCommit**, **CodeBuild**, **ECR**, and **CodeDeploy**.

**IAM Policy for CodePipeline**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:GitPull",
        "codebuild:StartBuild",
        "codedeploy:CreateDeployment",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### **7. AWS EC2 (Compute Service for Deployment)**

**Steps**:
- Set up EC2 instances in both **UAT** and **Production** environments.
- Install the **CodeDeploy agent** on these instances to facilitate deployment.
- **Tag** EC2 instances with `Environment=uat` for UAT and `Environment=prod` for production.

**IAM Role and Policy for EC2**:
- EC2 instances need permissions to interact with **CodeDeploy** and pull Docker images from **ECR**.

**IAM Policy for EC2 Instance Role**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:DownloadFile",
        "codedeploy:CreateDeployment",
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "*"
    }
  ]
}
```

### **8. AWS IAM (Identity and Access Management)**

**Steps**:
- Set up **IAM roles** for each service (CodeCommit, CodeBuild, CodeDeploy, CodePipeline, EC2) with the necessary permissions.
- Create **service-linked roles** for **CodeBuild**, **CodeDeploy**, and **CodePipeline** if they don't already exist.

**IAM Policy for CodePipeline Service Role**:
- **CodePipeline** requires a role to manage the entire pipeline flow, allowing interactions with **CodeCommit**, **CodeBuild**, **ECR**, **CodeDeploy**, and **CloudWatch**.


Certainly! Below is the completed **IAM Policy for CodePipeline Service Role**:

### **IAM Policy for CodePipeline Service Role**:
The **CodePipeline** service role requires permissions to manage the entire pipeline flow, allowing interactions with **CodeCommit**, **CodeBuild**, **ECR**, **CodeDeploy**, and **CloudWatch** for logging.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:GitPull",
        "codebuild:StartBuild",
        "codedeploy:CreateDeployment",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "cloudwatch:PutMetricData",
        "cloudwatch:DescribeAlarms"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codecommit:DescribeRepository",
        "codebuild:BatchGetBuilds",
        "codedeploy:GetDeployment",
        "codedeploy:GetDeploymentGroup",
        "codedeploy:ListDeployments",
        "cloudwatch:ListMetrics"
      ],
      "Resource": "*"
    }
  ]
}
```

## Conclusion

By following this guide, you've built a fully automated CI/CD pipeline using **AWS CodeCommit**, **CodeBuild**, **ECR**, **CodeDeploy**, **EC2**, and **AWS Secrets Manager**. This pipeline will allow you to securely and efficiently deploy your Python Flask application to UAT environments, minimizing manual intervention and enhancing your software delivery process.

With **AWS Secrets Manager**, sensitive credentials are securely stored and accessed during the build and deployment processes, ensuring that your application remains secure and compliant.

---

### Additional Resources

- [AWS CodeCommit Documentation](https://docs.aws.amazon.com/codecommit/latest/userguide/welcome.html)
- [AWS CodeBuild Documentation](https://docs.aws.amazon.com/codebuild/latest/userguide/welcome.html)
- [AWS CodeDeploy Documentation](https://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html)
- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html)

---
