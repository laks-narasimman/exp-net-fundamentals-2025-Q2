#!/usr/bin/env bash

# -------------------------------
# Deploy VPC CloudFormation Stack
# -------------------------------

# === Required: Provide the stack name ===
STACK_NAME=$1

# === Optional: Override default parameter values ===
VPC_CIDR=${2:-"10.200.123.0/24"}
PUBLIC_SUBNET_CIDR=${3:-"10.200.123.0/25"}
PRIVATE_SUBNET_CIDR=${4:-"10.200.123.128/25"}
AZ=${5:-"us-east-1a"}
REGION="us-east-1"

# === Template file (from /var directory) ===
TEMPLATE_FILE="cft.yaml"

if [ -z "$STACK_NAME" ]; then
  echo "Usage: $0 <STACK_NAME> [VPC_CIDR] [PUBLIC_SUBNET_CIDR] [PRIVATE_SUBNET_CIDR] [AZ]"
  exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Template file not found at $TEMPLATE_FILE"
  exit 1
fi

echo "Validating CloudFormation template..."
aws cloudformation validate-template --template-body file://$TEMPLATE_FILE
if [ $? -ne 0 ]; then
  echo "Template validation failed."
  exit 1
fi

echo "Deploying stack: $STACK_NAME in region $REGION..."
aws cloudformation create-stack \
  --region $REGION \
  --stack-name $STACK_NAME \
  --template-body file://$TEMPLATE_FILE \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=VpcCidr,ParameterValue="$VPC_CIDR" \
    ParameterKey=PublicSubnetCidr,ParameterValue="$PUBLIC_SUBNET_CIDR" \
    ParameterKey=PrivateSubnetCidr,ParameterValue="$PRIVATE_SUBNET_CIDR" \
    ParameterKey=AvailabilityZone,ParameterValue="$AZ" \
    ParameterKey=EnableDnsHostnames,ParameterValue=true \
    ParameterKey=EnableDnsSupport,ParameterValue=true

echo "Waiting for stack creation to complete..."
aws cloudformation wait stack-create-complete \
  --region $REGION \
  --stack-name $STACK_NAME

echo "Stack $STACK_NAME deployed successfully."
echo "Outputs:"
aws cloudformation describe-stacks \
  --region $REGION \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs" \
  --output table
