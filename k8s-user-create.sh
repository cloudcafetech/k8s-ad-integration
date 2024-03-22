#!/bin/bash

orgname="Cloud Cafe"

name=${1}
K8SGROUP=${2}
USERPATH="./users/${name}"

if [ -z ${name} ]; then
    echo "User name is required."
    echo "Usage: $0 <name> <namespace>"
    exit 1
fi

if [ -z ${K8SGROUP} ]; then
    echo "K8s Namespace is required."
    echo "Usage: $0 <name> <namespace>"
    exit 1
fi

if [ -d ${USERPATH} ]; then
    echo "User already exists."
    exit 1
else
    mkdir -p ${USERPATH}
fi

echo "Generating signing request."

# Generate a private key
openssl genrsa -out ${USERPATH}/"$name".key 4096

# Create a certificate signing request
openssl req -new -key ${USERPATH}/"$name".key -out ${USERPATH}/"$name".csr -subj "/CN=$name/O=$orgname"

# CSR base64 data in variable
REQDATA=`cat ${USERPATH}/"$name".csr | base64 | tr -d "\n"`

cat <<EOF> ${USERPATH}/"$name"-csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $name
spec:
  #signerName: kubernetes.io/kube-apiserver-client
  #groups:
  #- system:authenticated
  request: $REQDATA
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 31536000 # 1 year
  usages:
  #- key encipherment
  - client auth
EOF

echo
echo "Approving signing request."
kubectl create -f ${USERPATH}/"$name"-csr.yaml
sleep 2
kubectl certificate approve $name

echo
echo "Downloading certificate." 
kubectl get csr $name -o jsonpath='{.status.certificate}' | base64 --decode > ${USERPATH}/"$name".crt

echo "Creating user ($name) kubeconfig"
cp ~/.kube/config ${USERPATH}/"$name"-kube-config  
sed -i '/contexts:/,$d' ${USERPATH}/"$name"-kube-config  

# Set Cluster Configuration:
kubectl config set-cluster kubernetes --kubeconfig=${USERPATH}/"$name"-kube-config
kubectl config set-credentials "$name" --client-certificate=${USERPATH}/"$name".crt --client-key=${USERPATH}/"$name".key --embed-certs=true --kubeconfig=${USERPATH}/"$name"-kube-config
kubectl config set-context "$name"-context --cluster=kubernetes --namespace=${K8SGROUP} --user="$name" --kubeconfig=${USERPATH}/"$name"-kube-config
kubectl config use-context "$name"-context --kubeconfig=${USERPATH}/"$name"-kube-config

echo
echo "Next, add a role-binding for user ($name)"

# Add RBAC rules for the user or their group.
#kubectl create role pod-manager --verb=create,list,get --resource=pods --namespace=${K8SGROUP}
#kubectl create rolebinding "$name"-pod-manager --role=pod-manager --user="$name" --namespace=${K8SGROUP}
