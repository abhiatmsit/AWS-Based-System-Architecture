#!/bin/bash
# AWS VPC End-to-End Automation Script
# Requires AWS CLI configured with VPC permissions

# ===== CONFIGURATION =====
VPC_CIDR="10.0.0.0/16"
UPDATED_VPC_CIDR="10.1.0.0/16"
SUBNET_CIDR="10.0.1.0/24"
REGION="us-east-1"
TAG_NAME="TestVPC"

# =========================
# 1️⃣ CREATE VPC
# =========================
echo "=== Creating VPC ==="
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $VPC_CIDR \
    --region $REGION \
    --query "Vpc.VpcId" \
    --output text)
echo "✅ VPC Created: $VPC_ID"

# Tag the VPC
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$TAG_NAME

# =========================
# 2️⃣ CREATE SUBNET
# =========================
echo "=== Creating Subnet ==="
SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block $SUBNET_CIDR \
    --region $REGION \
    --query "Subnet.SubnetId" \
    --output text)
echo "✅ Subnet Created: $SUBNET_ID"

# =========================
# 3️⃣ CREATE INTERNET GATEWAY
# =========================
echo "=== Creating Internet Gateway ==="
IGW_ID=$(aws ec2 create-internet-gateway \
    --query "InternetGateway.InternetGatewayId" \
    --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "✅ IGW Created and Attached: $IGW_ID"

# =========================
# 4️⃣ CREATE ROUTE TABLE
# =========================
echo "=== Creating Route Table ==="
RTB_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --query "RouteTable.RouteTableId" \
    --output text)
aws ec2 associate-route-table --route-table-id $RTB_ID --subnet-id $SUBNET_ID
aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
echo "✅ Route Table Created: $RTB_ID"

# =========================
# 5️⃣ LIST VPCs
# =========================
echo "=== Listing VPCs ==="
aws ec2 describe-vpcs \
    --query "Vpcs[].{ID:VpcId,CIDR:CidrBlock,State:State}" \
    --output table

# =========================
# 6️⃣ UPDATE VPC (Workaround: Create New & Migrate)
# =========================
echo "=== Updating VPC CIDR (Workaround) ==="
# AWS does not allow direct CIDR change for VPC, so we create a new one
NEW_VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $UPDATED_VPC_CIDR \
    --region $REGION \
    --query "Vpc.VpcId" \
    --output text)
aws ec2 create-tags --resources $NEW_VPC_ID --tags Key=Name,Value="${TAG_NAME}-Updated"
echo "✅ New VPC Created: $NEW_VPC_ID"

# =========================
# 7️⃣ DELETE OLD VPC
# =========================
echo "=== Deleting Old VPC Resources ==="
# Detach and delete IGW
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# Delete subnet
aws ec2 delete-subnet --subnet-id $SUBNET_ID

# Delete route table
aws ec2 delete-route-table --route-table-id $RTB_ID

# Delete old VPC
aws ec2 delete-vpc --vpc-id $VPC_ID
echo "✅ Old VPC Deleted"

# =========================
# 8️⃣ DELETE UPDATED VPC
# =========================
echo "=== Deleting Updated VPC ==="
aws ec2 delete-vpc --vpc-id $NEW_VPC_ID
echo "✅ Updated VPC Deleted"

echo "🎯 VPC Lifecycle Complete"

