#!/bin/bash
set -e

LF_PERMISSIONS_TEMPLATE=lake-permissions.template
usage() { 
    echo "Usage: $0 [-s <stack_name>] [-b <bucket_name>] [-v <vpc_cidr>] [-e <lake>]" 1>&2; exit 1; 
}

enable_lake_permissions() {
  ENABLE_LAKE_PERMISSIONS=false
}

while getopts ":s:b:v:e:" o; do
    case "${o}" in
        s)
            STACK_NAME=${OPTARG}
            ;;
        b)
            S3_BUCKET=${OPTARG}
            ;;
        e)
            if [ "$OPTARG" == "lake" ]; then enable_lake_permissions
            else echo "Unrecognised service to enable $OPTARG"; exit 1 
            fi
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

TMP_DIR=/tmp

aws cloudformation package  \
  --template-file ./templates/${LF_PERMISSIONS_TEMPLATE} \
  --s3-bucket ${S3_BUCKET} \
  --output-template-file  ${TMP_DIR}/${LF_PERMISSIONS_TEMPLATE}

aws cloudformation deploy \
  --template-file ${TMP_DIR}/${LF_PERMISSIONS_TEMPLATE} \
  --s3-bucket ${S3_BUCKET} \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
  --stack-name ${STACK_NAME}

