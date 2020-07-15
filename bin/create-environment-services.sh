#!/bin/bash
set -e
usage() { 
    echo "Usage: $0 -s <stack_name> -b <bucket_name> -v <vpc_cidr> -i <vpc_id> -s <public_subnets> -p <private_subnets> [-e <ad|bastion|public_bastion>] [-r region] [-d domain_name]" 1>&2; exit 1; 
}

ENABLE_BASTION=false;
ENABLE_PUBLIC_BASTION=false;
ENABLE_BASTION_FULL_ACCESS_FROM_CIDR=""
ENABLE_AD=false
DOMAIN_NAME=""

enable_bastion() {
  ENABLE_BASTION=true;
  ENABLE_PUBLIC_BASTION=false;
  ENABLE_BASTION_FULL_ACCESS_FROM_CIDR=""
#"$(curl -s https://ipconfig.io)/32" 
}


enable_public_bastion() {
  ENABLE_BASTION=true;
  ENABLE_PUBLIC_BASTION=true;
  ENABLE_BASTION_FULL_ACCESS_FROM_CIDR=""
#"$(curl -s https://ipconfig.io)/32" 
}


enable_ad() { 
  ENABLE_AD=true
}

while getopts ":s:b:v:e:r:i:n:p:d:h" o; do
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
        d | --domain)
          DOMAIN_NAME=${OPTARG}
          ;;
        e | --enable)
            if [ "$OPTARG" == "bastion" ]; then enable_bastion
            elif [ "$OPTARG" == "public_bastion" ]; then enable_public_bastion
            elif [ "$OPTARG" == "ad" ]; then enable_ad
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
TRANSIT_GATEWAY_ID=""
TEMPLATE_FILE=environment-services.template
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
    EnableBastionAccess=${ENABLE_BASTION} \
    EnablePublicBastion=${ENABLE_PUBLIC_BASTION} \
    EnableBastionFullAccessFromCidr=${ENABLE_BASTION_FULL_ACCESS_FROM_CIDR} \
    EnableActiveDirectory=${ENABLE_AD}  \
    TransitGatewayId=${TRANSIT_GATEWAY_ID} \
    DomainName=${DOMAIN_NAME} \
    --capabilities CAPABILITY_IAM \
    --stack-name ${STACK_NAME}

aws cloudformation describe-stacks \
  --region ${REGION} \
  --stack-name ${STACK_NAME} \
  --output table \
  --query 'Stacks[].Outputs'
