#!/bin/bash
STACK_NAME=$1
S3_BUCKET=$2
TMP_DIR=/tmp
aws cloudformation package  \
  --template-file ./templates/environment.template \
  --s3-bucket ${S3_BUCKET} \
  --output-template-file  ${TMP_DIR}/environment.template

aws cloudformation deploy \
  --template-file ${TMP_DIR}/environment.template \
  --s3-bucket ${S3_DIR} \
  --parameter-overrides \
    VpcCidr=10.0.0.0/16 \
    EnableBastionAccess='true' \
    --capabilities CAPABILITY_IAM \
    --stack-name ${STACK_NAME}




