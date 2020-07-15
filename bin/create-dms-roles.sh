#!/bin/bash
set -e
usage() { 
    echo "Usage: $0 [-s <stack_name>] [-b <bucket_name>]  -r [region] " 1>&2; exit 1; 
}

while getopts ":s:b:r:" o; do
    case "${o}" in
        s)
            STACK_NAME=${OPTARG}
            ;;
        b)
            S3_BUCKET=${OPTARG}
            ;;
        r)
            REGION=${OPTARG}
            ;;
        \?)
            echo "ERROR: Invalid option -$OPTARG"
            usage
            ;;
    esac
done

if [ -z "${STACK_NAME}" ] || [ -z "${S3_BUCKET}" ]; then
  usage 
fi

if [ -z ${REGION} ]; then
  REGION=eu-west-1
fi

TMP_DIR=/tmp
TEMPLATE_FILE=dms-roles.template
VPCID=vpc-08e42e4c8f6f999e7
aws cloudformation package  \
  --region ${REGION} \
  --template-file ./templates/${TEMPLATE_FILE} \
  --s3-bucket ${S3_BUCKET} \
  --output-template-file  ${TMP_DIR}/${TEMPLATE_FILE}

aws cloudformation deploy \
  --region ${REGION} \
  --template-file ${TMP_DIR}/${TEMPLATE_FILE} \
  --s3-bucket ${S3_BUCKET} \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --stack-name ${STACK_NAME}

