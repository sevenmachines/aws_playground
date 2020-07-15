#!/bin/bash
set -e
usage() { 
    echo "Usage: $0 -s <stack_name> -b <bucket_name> -v <vpc_cidr> [-r region] -d [domain_name]" 1>&2; exit 1; 
}

while getopts ":s:b:v:r:d:" o; do
    case "${o}" in
        s)
            STACK_NAME=${OPTARG}
            ;;
        b)
            S3_BUCKET=${OPTARG}
            ;;
        v)
            VPCCIDR=${OPTARG}
            ;;
        r)
            REGION=${OPTARG}
            ;;
        d)
        	DOMAIN_NAME=${OPTARG}
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
if [ -z "${VPCCIDR}" ]; then
  VPCCIDR="10.0.0.0/16"
fi
if [ -z "${DOMAIN_NAME}" ]; then
  DOMAIN_NAME=""
fi

TMP_DIR=/tmp

aws cloudformation package  \
  --region ${REGION} \
  --template-file ./templates/environment-base.template \
  --s3-bucket ${S3_BUCKET} \
  --output-template-file  ${TMP_DIR}/environment-base.template

aws cloudformation deploy \
  --region ${REGION} \
  --template-file ${TMP_DIR}/environment-base.template \
  --s3-bucket ${S3_BUCKET} \
  --parameter-overrides \
    VpcCidr=${VPCCIDR} \
    DomainName=${DOMAIN_NAME} \
    --capabilities CAPABILITY_IAM \
    --stack-name ${STACK_NAME}

aws cloudformation describe-stacks \
  --region ${REGION} \
  --stack-name ${STACK_NAME} \
  --output table \
  --query 'Stacks[].Outputs'
