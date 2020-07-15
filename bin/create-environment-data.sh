#!/bin/bash
set -x
set -e
usage() { 
    echo "Usage: $0 -s <stack_name> -b <bucket_name> -v <vpc_cidr> -i <vpc_id> -s <public_subnets> -p <private_subnets> [-e <redshify|aurora|legacydb|emr|ad|bastion|public_bastion>] [-r region] [-d domain_name]" 1>&2; exit 1; 
}

ENABLE_REDSHIFT=false
ENABLE_AURORA=false
ENABLE_LEGACY_DATABASE=false
ENABLE_EMR=false
ENABLE_DMS=false
ENABLE_GLUE=false

enable_redshift() { 
  ENABLE_REDSHIFT=true
}
enable_ad() { 
  ENABLE_AD=true
}
enable_aurora() {
  ENABLE_AURORA=true
}
enable_legacy_database() {
  ENABLE_LEGACY_DATABASE=true
}
enable_dms() {
  ENABLE_DMS=true
}
enable_emr() {
  ENABLE_EMR=true
}

enable_glue() {
  ENABLE_GLUE=true
}

while getopts ":s:b:v:e:r:i:n:p:h" o; do
    case "${o}" in
        s | --name)
            STACK_NAME=${OPTARG}
            ;;
        b | --bucket)
            S3_BUCKET=${OPTARG}
            ;;
        v | --vpc_cidr)
            VPC_CIDR=${OPTARG}
            ;;
        i | --vpc_id)
            VPC_ID=${OPTARG}
            ;;
        n | --public_subnets)
            PUBLIC_SUBNETS=${OPTARG}
            ;;
        p | --private_subnets)
            PRIVATE_SUBNETS=${OPTARG}
            ;;
        r | --region)
            REGION=${OPTARG}
            ;;
        e | --enable)
            if [ "$OPTARG" == "redshift" ]; then enable_redshift
            elif [ "$OPTARG" == "aurora" ]; then enable_aurora
            elif [ "$OPTARG" == "legacydb" ]; then enable_legacy_database
            elif [ "$OPTARG" == "emr" ]; then enable_emr
            elif [ "$OPTARG" == "glue" ]; then enable_glue
            elif [ "$OPTARG" == "dms" ]; then enable_dms
            else echo "Unrecognised service to enable $OPTARG"; exit 1 
            fi
            ;;
        \?)
            echo "ERROR: Invalid option -$OPTARG"
            usage
            ;;
    esac
done

if [ -z "${STACK_NAME}" ] || [ -z "${S3_BUCKET}" ] || [ -z "${VPC_CIDR}" ] || [ -z "${VPC_ID}" ] || [ -z "${PUBLIC_SUBNETS}" ] || [ -z "${PRIVATE_SUBNETS}" ]; then
  usage 
fi

if [ -z ${REGION} ]; then
  REGION=eu-west-1
fi

RANDINT=$(( 1 +  (${RANDOM} % 250) ))
TMP_DIR=/tmp
REDSHIFT_DATABASE_NAME=redshift
AURORA_DATABASE_NAME=aurora
AURORA_USERNAME=niall
LEGACY_DATABASE_NAME=legacydb
LEGACY_DATABASE_USERNAME=niall
REDSHIFT_USERNAME=niall
TEMPLATE_FILE=environment-data.template
aws cloudformation package  \
  --region ${REGION} \
  --template-file ./templates/${TEMPLATE_FILE} \
  --s3-bucket ${S3_BUCKET} \
  --output-template-file  ${TMP_DIR}/${TEMPLATE_FILE}
echo Saved template to ${TMP_DIR}/${TEMPLATE_FILE}...

aws cloudformation deploy \
  --region ${REGION} \
  --template-file ${TMP_DIR}/${TEMPLATE_FILE} \
  --s3-bucket ${S3_BUCKET} \
  --parameter-overrides \
    VpcCidr=${VPC_CIDR} \
    VpcId=${VPC_ID} \
    PublicSubnetIds=${PUBLIC_SUBNETS} \
    PrivateSubnetIds=${PRIVATE_SUBNETS} \
    EnableRedshift=${ENABLE_REDSHIFT}  \
    EnableDMS=${ENABLE_DMS}  \
    RedshiftDatabaseName=${REDSHIFT_DATABASE_NAME} \
    RedshiftUsername=${REDSHIFT_USERNAME} \
    EnableAurora=${ENABLE_AURORA}  \
    EnableGlue=${ENABLE_GLUE}  \
    AuroraDatabaseName=${AURORA_DATABASE_NAME} \
    AuroraUsername=${AURORA_USERNAME} \
    EnableLegacyDatabase=${ENABLE_LEGACY_DATABASE}  \
    LegacyDatabaseName=${LEGACY_DATABASE_NAME} \
    LegacyDatabaseUsername=${LEGACY_DATABASE_USERNAME} \
    --capabilities CAPABILITY_IAM \
    --stack-name ${STACK_NAME}

aws cloudformation describe-stacks \
  --region ${REGION} \
  --stack-name ${STACK_NAME} \
  --output table \
  --query 'Stacks[].Outputs'
