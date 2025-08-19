#!/bin/bash
# AWS IAM End-to-End Script
# Requires AWS CLI configured with IAM permissions

# ===== CONFIGURATION =====
IAM_USER="TestUser"
IAM_GROUP="TestGroup"
IAM_POLICY_NAME="TestPolicy"
IAM_ROLE="TestRole"
POLICY_DOCUMENT="policy.json"
ROLE_TRUST_DOCUMENT="trust.json"

# ===== 1. CREATE IAM USER =====
echo "=== Creating IAM User ==="
aws iam create-user --user-name $IAM_USER
echo "IAM User created: $IAM_USER"

# ===== 2. CREATE IAM POLICY =====
cat > $POLICY_DOCUMENT <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        }
    ]
}
EOF

echo "=== Creating IAM Policy ==="
POLICY_ARN=$(aws iam create-policy \
    --policy-name $IAM_POLICY_NAME \
    --policy-document file://$POLICY_DOCUMENT \
    --query 'Policy.Arn' \
    --output text)
echo "IAM Policy created: $POLICY_ARN"

# ===== 3. CREATE IAM GROUP & ADD USER =====
echo "=== Creating IAM Group ==="
aws iam create-group --group-name $IAM_GROUP
aws iam add-user-to-group --user-name $IAM_USER --group-name $IAM_GROUP
echo "User $IAM_USER added to group $IAM_GROUP"

# Attach policy to group
aws iam attach-group-policy --group-name $IAM_GROUP --policy-arn $POLICY_ARN
echo "Policy attached to group."

# ===== 4. CREATE IAM ROLE =====
cat > $ROLE_TRUST_DOCUMENT <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

echo "=== Creating IAM Role ==="
aws iam create-role \
    --role-name $IAM_ROLE \
    --assume-role-policy-document file://$ROLE_TRUST_DOCUMENT
echo "IAM Role created: $IAM_ROLE"

# Attach policy to role
aws iam attach-role-policy --role-name $IAM_ROLE --policy-arn $POLICY_ARN
echo "Policy attached to role."

# ===== 5. UPDATE IAM RESOURCES =====
# Example: Update IAM User name
NEW_USER_NAME="UpdatedUser"
echo "=== Updating IAM User Name ==="
aws iam update-user --user-name $IAM_USER --new-user-name $NEW_USER_NAME
IAM_USER=$NEW_USER_NAME
echo "IAM User renamed to $IAM_USER"

# Example: Update IAM Group name
NEW_GROUP_NAME="UpdatedGroup"
aws iam update-group --group-name $IAM_GROUP --new-group-name $NEW_GROUP_NAME
IAM_GROUP=$NEW_GROUP_NAME
echo "IAM Group renamed to $IAM_GROUP"

# ===== 6. DELETE IAM RESOURCES =====
echo "=== Deleting IAM Resources ==="
# Detach policies
aws iam detach-group-policy --group-name $IAM_GROUP --policy-arn $POLICY_ARN
aws iam detach-role-policy --role-name $IAM_ROLE --policy-arn $POLICY_ARN

# Remove user from group
aws iam remove-user-from-group --user-name $IAM_USER --group-name $IAM_GROUP

# Delete role
aws iam delete-role --role-name $IAM_ROLE

# Delete group
aws iam delete-group --group-name $IAM_GROUP

# Delete policy
aws iam delete-policy --policy-arn $POLICY_ARN

# Delete user
aws iam delete-user --user-name $IAM_USER

# Clean up temp files
rm -f $POLICY_DOCUMENT $ROLE_TRUST_DOCUMENT

echo "All IAM resources deleted successfully."
