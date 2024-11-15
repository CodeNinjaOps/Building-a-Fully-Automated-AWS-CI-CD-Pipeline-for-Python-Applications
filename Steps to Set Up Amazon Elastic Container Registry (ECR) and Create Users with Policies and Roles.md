### Steps to Set Up Amazon Elastic Container Registry (ECR) and Create Users with Policies and Roles

#### Step 1: Create an ECR Repository
1. **Sign in to AWS Console**: Navigate to **ECR** (Elastic Container Registry).
2. **Create Repository**:
   - In the **Amazon ECR** console, click on **Create repository**.
   - Choose a repository name (e.g., `my-python-app-repo`).
   - For visibility, choose either **Public** or **Private** (private is recommended for most use cases).
   - Click **Create repository**.
   
   Once the repository is created, you will be given the repository URI (URL) which you will use to push images to this repository.

#### Step 2: Set Up Docker CLI and Push Docker Image to ECR

1. **Install and Configure Docker CLI**:
   - If you haven't already, install Docker on your machine: [Install Docker](https://docs.docker.com/get-docker/).
   - Authenticate Docker to your ECR registry using the AWS CLI. This allows Docker to push images to ECR.
     ```bash
     aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<your-region>.amazonaws.com
     ```

2. **Build Docker Image**:
   - Navigate to the directory containing your `Dockerfile` (ensure it’s ready to build your application image).
     ```bash
     docker build -t my-python-app .
     ```

3. **Tag Docker Image**:
   - After building your image, tag it with the ECR repository URI.
     ```bash
     docker tag my-python-app:latest <aws_account_id>.dkr.ecr.<your-region>.amazonaws.com/my-python-app-repo:latest
     ```

4. **Push Docker Image to ECR**:
   - Push the image to your ECR repository:
     ```bash
     docker push <aws_account_id>.dkr.ecr.<your-region>.amazonaws.com/my-python-app-repo:latest
     ```

#### Step 3: Set Up IAM User and Policy for ECR Access

To push and pull images from ECR, users need permissions. Below are the steps to create a user with the necessary IAM policy for interacting with ECR.

1. **Create IAM User**:
   - In the AWS Console, go to **IAM** > **Users** > **Add user**.
   - Enter a username (e.g., `ecr-user`).
   - Select **Programmatic access** (this provides access via AWS CLI or APIs).
   - Click **Next: Permissions**.

2. **Attach Policies for ECR Access**:
   You need to attach a policy that grants permissions to push and pull images from ECR.

   **Option 1: Attach Managed Policy for Amazon ECR**:
   - Attach the **AmazonEC2ContainerRegistryFullAccess** managed policy to the user.
   
   **Option 2: Custom Policy for Fine-Grained Access**:
   If you want to create a custom policy, use the following example that grants permissions to push and pull images from ECR:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ecr:BatchCheckLayerAvailability",
           "ecr:GetAuthorizationToken",
           "ecr:BatchGetImage",
           "ecr:PutImage",
           "ecr:InitiateLayerUpload",
           "ecr:UploadLayerPart",
           "ecr:CompleteLayerUpload"
         ],
         "Resource": "arn:aws:ecr:<your-region>:<your-account-id>:repository/my-python-app-repo"
       }
     ]
   }
   ```

3. **Download Credentials**:
   - After the user is created, download the credentials file containing the **Access Key** and **Secret Key**.

To convert the provided steps for **EC2** (instead of ECS or EKS), you need to ensure that the **EC2 instance** has the correct **IAM role** and **permissions** to interact with **Amazon ECR**. Here's how you can set up the IAM role and policies for EC2 to interact with ECR.

### Step 1: Set Up IAM Role for EC2 to Pull Images from ECR

When using **EC2** to pull images from **ECR**, you'll need an IAM role that the EC2 instance can assume to access ECR.

#### 1.1 Create an IAM Role for EC2

1. **Go to IAM Console**:
   - Navigate to **IAM** > **Roles** > **Create role**.

2. **Create Role for EC2**:
   - Select **AWS service** and then **EC2**.
   - Click **Next: Permissions**.

3. **Attach Permissions**:
   - Attach the **AmazonEC2ContainerRegistryReadOnly** policy for **read-only access** (if the EC2 instance only needs to pull images) or **AmazonEC2ContainerRegistryFullAccess** (if you want to give the EC2 instance full access to ECR to push and pull images).
   - **AmazonEC2ContainerRegistryReadOnly**: This policy allows EC2 instances to pull images from ECR but not push them.
   - **AmazonEC2ContainerRegistryFullAccess**: This policy grants both pull and push access.

4. **Review and Create**:
   - Review the settings and give the role a name (e.g., `EC2-ECR-Access-Role`).
   - Click **Create role**.

#### 1.2 Attach the IAM Role to Your EC2 Instance

1. **Navigate to EC2 Console**:
   - Go to the **EC2** dashboard in the AWS Management Console.

2. **Select EC2 Instance**:
   - Select the EC2 instance that will interact with ECR.

3. **Attach Role**:
   - In the **Actions** dropdown, select **Security** > **Modify IAM role**.
   - Attach the newly created role (`EC2-ECR-Access-Role`).
   - Click **Update IAM role**.

### Step 2: Configure EC2 to Authenticate with ECR

Once the IAM role is attached to the EC2 instance, the instance will automatically assume the role when interacting with AWS services. Now, you need to authenticate **Docker** to use **ECR** from the EC2 instance.

#### 2.1 Install AWS CLI and Docker on EC2 (if not already installed)

- Ensure that **AWS CLI** and **Docker** are installed on the EC2 instance.
  
```bash
# Install AWS CLI (if not installed)
sudo apt-get install awscli

# Install Docker (if not installed)
sudo apt-get install docker.io
```

#### 2.2 Authenticate Docker to ECR

On the EC2 instance, run the following command to authenticate Docker using the IAM role credentials:

```bash
aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<your-region>.amazonaws.com
```

This command retrieves an authentication token from ECR and logs Docker into the registry, allowing you to pull images from ECR.

### Step 3: Pull Docker Images from ECR on EC2

Now that your EC2 instance is authenticated with ECR, you can pull Docker images from the repository.

#### 3.1 Pull Docker Image

```bash
docker pull <aws_account_id>.dkr.ecr.<your-region>.amazonaws.com/my-python-app-repo:latest
```

Replace `<aws_account_id>`, `<your-region>`, and `my-python-app-repo` with your ECR repository details.

### IAM Policies Summary for EC2

#### IAM Policy for Developer/User (to push and pull images from ECR):

If you need to allow developers or other IAM users to **push** and **pull** Docker images, you can use this IAM policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "arn:aws:ecr:<your-region>:<your-account-id>:repository/my-python-app-repo"
    }
  ]
}
```

This policy allows IAM users to interact with the specified ECR repository by pulling and pushing Docker images.

#### IAM Role for EC2 (to pull images from ECR):

For the EC2 instance, the IAM role should have permissions to pull images from ECR. Use the following policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "arn:aws:ecr:<your-region>:<your-account-id>:repository/my-python-app-repo"
    }
  ]
}
```

This IAM role will grant EC2 instances the necessary permissions to pull images from ECR.

### Summary

- **IAM Role for EC2**: Create an IAM role for EC2 with the `AmazonEC2ContainerRegistryReadOnly` (for pull-only access) or `AmazonEC2ContainerRegistryFullAccess` (for full access).
- **Attach Role to EC2 Instance**: Attach the IAM role to your EC2 instance that needs to pull/push images from ECR.
- **Authenticate Docker to ECR**: Use `aws ecr get-login-password` to authenticate Docker on the EC2 instance to interact with ECR.
- **Pull Images from ECR**: Use Docker commands to pull images from ECR.

This setup allows your **EC2** instance to interact with **ECR** for pulling (and optionally pushing) Docker images.