#!/bin/bash
# AWS EC2 End-to-End Script
# Make sure AWS CLI is installed and configured (aws configure)

# ==== CONFIGURE THESE ====
AMI_ID="ami-020cba7c55df1f615"                # Example: ami-0abcdef1234567890
INSTANCE_TYPE="t3.micro"
KEY_NAME="devops_project"                  # Your existing AWS key pair
#SECURITY_GROUP_ID="020b4a0c03c916b4c"
SUBNET_ID="subnet-0b9f42c1ac096c189"
INSTANCE_NAME="TestInstance"

echo "=== 1. CREATE INSTANCE ==="
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --subnet-id $SUBNET_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query "Instances[0].InstanceId" \
    --output text)

echo "Created instance with ID: $INSTANCE_ID"

echo "Waiting for instance to start..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo "Instance is now running."

echo "=== 2. LIST INSTANCE ==="
aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress,Tags[?Key=='Name']|[0].Value]" \
    --output table

echo "=== 3. UPDATE INSTANCE TYPE ==="
NEW_INSTANCE_TYPE="t2.small"
echo "Stopping instance..."
aws ec2 stop-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID

echo "Modifying instance type to $NEW_INSTANCE_TYPE..."
aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --instance-type "{\"Value\": \"$NEW_INSTANCE_TYPE\"}"

echo "Starting instance..."
aws ec2 start-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo "Instance type updated."

echo "=== 4. DELETE INSTANCE ==="
echo "Terminating instance..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
echo "Instance terminated."
