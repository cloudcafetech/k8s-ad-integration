#!/bin/bash

# Run LDAP Server

apt install ldap-utils -y
HIP=`ip -o -4 addr list enp1s0 | awk '{print $4}' | cut -d/ -f1`

# Install Docker
if ! command -v docker &> /dev/null;
then
  echo "MISSING REQUIREMENT: docker engine could not be found on your system. Please install docker engine to continue: https://docs.docker.com/get-docker/"
  echo "Trying to Install Docker..."
  if [[ $(uname -a | grep amzn) ]]; then
    echo "Installing Docker for Amazon Linux"
    amazon-linux-extras install docker -y
  else
    curl -s https://releases.rancher.com/install-docker/19.03.sh | sh
  fi    
fi
systemctl start docker
systemctl enable docker

docker run --name ldap-server -p 389:389 -p 636:636 \
--env LDAP_TLS_VERIFY_CLIENT=try \
--env LDAP_ORGANISATION="Cloudcafe Org" \
--env LDAP_DOMAIN="cloudcafe.org" \
--env LDAP_ADMIN_PASSWORD="StrongAdminPassw0rd" \
--detach osixia/openldap:latest

# Check LDAP Server UP & Running

sleep 10
until [ $(docker inspect -f {{.State.Running}}" ldap-server) "=="true ]; do echo "Waiting for LDAP to UP..." && sleep 1; done

# Add LDAP User & Group

wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/ldap-records.ldif
ldapadd -x -H ldap://$HIP -D "cn=admin,dc=cloudcafe,dc=org" -w StrongAdminPassw0rd -f ldap-records.ldif

# LDAP query (Verify)

ldapsearch -x -H ldap://$HIP -D "cn=admin,dc=cloudcafe,dc=org" -b "dc=cloudcafe,dc=org" -w "StrongAdminPassw0rd"
