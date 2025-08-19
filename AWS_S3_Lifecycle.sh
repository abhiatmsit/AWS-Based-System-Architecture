#!/bin/bash
# AWS S3 End-to-End Automation Script
# Requires AWS CLI configured with S3 permissions

# ===== CONFIGURATION =====
BUCKET_NAME="my-test-bucket-$RANDOM"
UPDATED_BUCKET_NAME="my-updated-bucket-$RANDOM"
TEST_FILE="testfile.txt"
UPDATED_FILE="updatedfile.txt"

# =========================
# 1️⃣ CREATE BUCKET
# =========================
echo "=== Creating S3 Bucket: $BUCKET_NAME ==="
aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region us-east-1
echo "✅ Bucket Created"

# =========================
# 2️⃣ LIST BUCKETS
# =========================
echo "=== Listing All Buckets ==="
aws s3api list-buckets --query "Buckets[].Name" --output table

# =========================
# 3️⃣ UPLOAD OBJECT
# =========================
echo "=== Uploading Test File to Bucket ==="
echo "This is a test file" > $TEST_FILE
aws s3 cp $TEST_FILE s3://$BUCKET_NAME/
echo "✅ File Uploaded"

# =========================
# 4️⃣ LIST OBJECTS
# =========================
echo "=== Listing Objects in Bucket ==="
aws s3api list-objects --bucket $BUCKET_NAME --query "Contents[].Key" --output table

# =========================
# 5️⃣ UPDATE OBJECT
# =========================
echo "=== Updating Object in Bucket ==="
echo "This is the updated content" > $UPDATED_FILE
aws s3 cp $UPDATED_FILE s3://$BUCKET_NAME/$TEST_FILE
echo "✅ Object Updated"

# =========================
# 6️⃣ RENAME BUCKET (Workaround: Copy + Delete)
# =========================
echo "=== Renaming Bucket to $UPDATED_BUCKET_NAME ==="
aws s3api create-bucket \
    --bucket $UPDATED_BUCKET_NAME \
    --region us-east-1
aws s3 sync s3://$BUCKET_NAME s3://$UPDATED_BUCKET_NAME
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3api delete-bucket --bucket $BUCKET_NAME
BUCKET_NAME=$UPDATED_BUCKET_NAME
echo "✅ Bucket Renamed"

# =========================
# 7️⃣ DELETE OBJECT
# =========================
echo "=== Deleting Object from Bucket ==="
aws s3 rm s3://$BUCKET_NAME/$TEST_FILE
echo "✅ Object Deleted"

# =========================
# 8️⃣ DELETE BUCKET
# =========================
echo "=== Deleting Bucket ==="
aws s3api delete-bucket --bucket $BUCKET_NAME
echo "✅ Bucket Deleted"

# Cleanup temp files
rm -f $TEST_FILE $UPDATED_FILE

echo "🎯 S3 Bucket and Objects Lifecycle Complete"
