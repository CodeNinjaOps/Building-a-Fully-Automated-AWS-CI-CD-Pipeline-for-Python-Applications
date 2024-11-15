### Steps to Set Up the Repository and Create the User with IAM Policies

#### Step 1: Create a Repository in AWS CodeCommit
1. **Sign in to AWS Console**: Navigate to AWS CodeCommit.
2. **Create Repository**:
   - Go to **CodeCommit** in the AWS Management Console.
   - Click **Create repository**.
   - Enter a name for your repository and click **Create**.
   
#### Step 2: Push Your Application Code to CodeCommit via Git
1. **Clone the Repository**:
   - After creating the repository, AWS will provide the repository URL.
   - Clone the repository to your local machine using Git:
     ```bash
     git clone https://git-codecommit.<region>.amazonaws.com/v1/repos/<repository-name>
     ```
   
2. **Push Code to CodeCommit**:
   - After cloning, navigate to the repository folder and copy your application files (including `Dockerfile`, `app.py`, `buildspec.yml`, etc.) to it.
   - Stage and commit the changes:
     ```bash
     git add .
     git commit -m "Initial commit"
     ```
   - Push the code to CodeCommit:
     ```bash
     git push origin master
     ```

#### Step 3: Set Up CodePipeline to Monitor the Repository
1. **Create a CodePipeline**:
   - In the AWS Management Console, navigate to **CodePipeline**.
   - Click **Create pipeline** and follow the instructions to set up the pipeline.
   - Choose **AWS CodeCommit** as the source provider and select your repository.
   - Select the default branch (e.g., `master`) to monitor for changes.

#### Step 4: Create IAM User for Developer and Attach CodeCommit Policy

To allow developers to push code to CodeCommit, you need to create a user with the appropriate IAM policy.

1. **Create IAM User**:
   - In the AWS Console, go to **IAM**.
   - Click **Users** > **Add user**.
   - Enter a username (e.g., `developer-user`).
   - Select **Programmatic access** to allow Git and CLI access.
   - Click **Next: Permissions**.

2. **Attach Policy for CodeCommit Access**:
   - Click **Attach policies directly**.
   - Click **Create policy**.
   - In the **JSON** tab, enter the IAM policy for the developer:
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
   - Click **Review policy**, give it a name (e.g., `CodeCommitPolicy`), and click **Create policy**.
   - Attach this policy to the user.

3. **Download Credentials**:
   - Once the user is created, download the credentials file (access key and secret key) for the user.

#### Step 5: Create IAM Role for CodePipeline
1. **Create CodePipeline Service Role**:
   - In the AWS Console, go to **IAM** > **Roles** > **Create role**.
   - Select **AWS service** and then **CodePipeline**.
   - Attach the **CodeCommit** policy to this role (the policy allowing CodePipeline to pull code from CodeCommit).
   
2. **Attach Policy for CodePipeline**:
   - Click **Attach policies directly** and create a new policy (or use the following):
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
   - Attach this policy to the role.

#### Step 6: CodePipeline Configuration
1. **Source Stage**: Select the **CodeCommit repository** in the source stage of your pipeline.
2. **Build and Deploy Stages**: Set up the build and deploy stages in CodePipeline with **AWS CodeBuild** and **AWS CodeDeploy** to deploy your application once changes are pushed to the repository.

### Final IAM Policies Summary

#### IAM Policy for Developer/User (to push code to CodeCommit):
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

#### IAM Policy for CodePipeline (to pull code from CodeCommit):
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

By following these steps, you'll have set up the repository, configured CodePipeline, and created the necessary IAM policies and roles to allow developers to push code and CodePipeline to pull the code from CodeCommit.