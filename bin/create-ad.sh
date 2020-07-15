#!/bin/bash
set -x
set -e
TEMPLATE_DIR=templates
TEMPLATE=active-directory.template

usage() { 
    echo "Usage: $0 [-s <stack_name>] [-b <bucket_name>] [-v <vpc_id>] [-n <subnet_ids>] [-f <fqdn>]" 1>&2; exit 1; 
}

while getopts ":s:b:v:n:f:" o; do
    case "${o}" in
        s)
            STACK_NAME=${OPTARG}
            ;;
        b)
            S3_BUCKET=${OPTARG}
            ;;
        v)
        	  VPC_ID=${OPTARG}
            ;;
        n)
        	  SUBNET_IDS=${OPTARG}
            ;;
        f)
        	  FQDN=${OPTARG}
            ;;
        \?)
            echo "ERROR: Invalid option -$OPTARG"
            usage
            ;;
    esac
done
if [ -z "${FQDN}" ]; then
  FQDN="corp.example.internal"
fi
if [ -z "${STACK_NAME}" ] || [ -z "${S3_BUCKET}" ] || [ -z "${VPC_ID}" ] || [ -z "${SUBNET_IDS}" ]; then
  usage 
fi


EXTRA_PARAMS="--parameter-overrides \
    SubnetIds=${SUBNET_IDS} \
    VpcId=${VPC_ID} \
    FQDN=${FQDN}"

TMP_DIR=/tmp

aws cloudformation package  \
  --template-file ${TEMPLATE_DIR}/${TEMPLATE} \
  --s3-bucket ${S3_BUCKET} \
  --output-template-file  ${TMP_DIR}/${TEMPLATE}

echo aws cloudformation deploy \
  --template-file ${TMP_DIR}/${TEMPLATE} \
  --s3-bucket ${S3_BUCKET} \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
  --stack-name ${STACK_NAME} \
  ${EXTRA_PARAMS}
