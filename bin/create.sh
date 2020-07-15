# Services
./tmp/create-environment-services.sh -b cf-templates-73rvh3tjtqvy-eu-west-2 -r eu-west-2 -v 10.200.0.0/16 -s core-services -i vpc-0aad897bd49d8e374 -n "subnet-092e6bf7bda583dc0,subnet-0c42d7a313e154b38,subnet-01119920a0df57c44" -p "subnet-06f3bac23f450440d,subnet-0eccf37b672fec827,subnet-0b56098e2bb3f80c9" -d directory.example.internal -e bastion -e ad

# Data
./tmp/create-environment-data.sh -b cf-templates-73rvh3tjtqvy-eu-west-2 -r eu-west-2 -v 10.200.0.0/16 -s core-data -i vpc-0aad897bd49d8e374 -n "subnet-092e6bf7bda583dc0,subnet-0c42d7a313e154b38,subnet-01119920a0df57c44" -p "subnet-06f3bac23f450440d,subnet-0eccf37b672fec827,subnet-0b56098e2bb3f80c9" -e aurora  -e glue

