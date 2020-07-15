#!/bin/bash
set -e
TEMPLATE_DIR=external/quickstart-microsoft-activedirectory/templates
TEMPLATE=ad-1.template

usage() { 
    echo "Usage: $0 [-s <stack_name>] [-b <bucket_name>] [-v <vpc_cidr>] [-e <lake>]" 1>&2; exit 1; 
}

while getopts ":s:b:p:" o; do
    case "${o}" in
        s)
            STACK_NAME=${OPTARG}
            ;;
        b)
            S3_BUCKET=${OPTARG}
            ;;
        p)
        	PASSWORD=${OPTARG}
            ;;
        \?)
            echo "ERROR: Invalid option -$OPTARG"
            usage
            ;;
    esac
done

EXTRA_PARAMS="--parameter-overrides \
    KeyPairName=niall-isengard-sandbox-eu-west-1 \
    VPCID= \
    PrivateSubnet1ID= \
    PrivateSubnet2ID= \
    DomainAdminUser=Admin \
    DomainAdminPassword=${PASSWORD} \
    ADServer1NetBIOSName=DC1 \
    ADServer1PrivateIP=10.0.4.10 \
    ADServer2NetBIOSName=DC2 \
    ADServer2PrivateIP=10.0.5.10 \
    DomainDNSName=eu-west-1.compute.internal \
    DomainNetBIOSName=sandbox \
    PrivateSubnet1ID=subnet-0ab97202c1cdf951a \
    PrivateSubnet2ID=subnet-0fc151d71b545670c \
    VPCCIDR=10.0.0.0/16 \
    VPCID=vpc-01ea7f2d5f6fc80d8"

if [ -z "${STACK_NAME}" ] || [ -z "${S3_BUCKET}" ] || [ -z "${PASSWORD}" ]; then
  usage 
fi

TMP_DIR=/tmp

aws cloudformation package  \
  --template-file ${TEMPLATE_DIR}/${TEMPLATE} \
  --s3-bucket ${S3_BUCKET} \
  --output-template-file  ${TMP_DIR}/${TEMPLATE}

aws cloudformation deploy \
  --template-file ${TMP_DIR}/${TEMPLATE} \
  --s3-bucket ${S3_BUCKET} \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
  --stack-name ${STACK_NAME} \
  ${EXTRA_PARAMS}
