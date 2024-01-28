#!/usr/bin/env bash
# Kubernetes host setup script using RKE2 for Debian & Redhat distribution

NODE=M
PUBIPM=`curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`
MASTERIP=1.1.1.1
#MASTERIP=`ip -o -4 addr list ens4 | awk '{print $4}' | cut -d/ -f1`

MASTERN=`hostname`
K8S_VER=1.28.0-00
#K8S_VER=1.26.0-00
K8S_VER_MJ=$(echo "$K8S_VER" | cut -c 1-4)
#K8S_LATEST=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt | cut -d v -f2)

if [[ -n $(uname -a | grep -iE 'ubuntu|debian') ]]; then 
 OS=Ubuntu
 HIP=`ip -o -4 addr list ens4 | awk '{print $4}' | cut -d/ -f1`
 #HIP=`ip -o -4 addr list enp1s0 | awk '{print $4}' | cut -d/ -f1`
else
 HIP=`ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1`
fi

## Installation based on OS

### For Debian distribution
if [[ "$OS" == "Ubuntu" ]]; then
 # Install some of the tools, we’ll need on our servers.
 apt update -y
 apt install apt-transport-https ca-certificates gpg nfs-common curl wget git net-tools unzip jq zip nmap telnet dos2unix apparmor ldap-utils -y
 # Stopping and disabling firewalld by running the commands on all servers
 systemctl stop ufw
 systemctl stop apparmor.service
 systemctl disable --now ufw
 systemctl disable --now apparmor.service 
### For Redhat distribution
else
 # Stopping and disabling firewalld & SELinux
 systemctl stop firewalld
 systemctl disable firewalld
 setenforce 0
 sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
 # Install some of the tools, we’ll need on our servers.
 yum install -y git curl wget bind-utils jq httpd-tools zip unzip nfs-utils go nmap telnet dos2unix java-1.7.0-openjdk
fi

## Installation based on OS 

# Setting up Kubernetes Master using RKE2
mkdir -p /etc/rancher/rke2

if [[ "$NODE" == "M" ]]; then
cat << EOF >  /etc/rancher/rke2/config.yaml
token: pkls-secret
write-kubeconfig-mode: "0644"
cluster-cidr: 192.168.0.0/16
service-cidr: 192.167.0.0/16
node-label:
- "region=master"
tls-san:
  - "$MASTERN"
  - "$MASTERIP"
  - "$PUBIPM"
disable:
  - rke2-ingress-nginx
  - rke2-snapshot-controller
  - rke2-snapshot-controller-crd
  - rke2-snapshot-validation-webhook
#  - rke2-coredns
#  - rke2-metrics-server
EOF

curl -sfL https://get.rke2.io | INSTALL_RKE2_CHANNEL=v$K8S_VER_MJ sh -
systemctl enable rke2-server.service
systemctl start rke2-server.service
echo "Check another window for Container UP"
sleep 20

mkdir ~/.kube
ln -s /etc/rancher/rke2/rke2.yaml ~/.kube/config  
chmod 600 /root/.kube/config
ln -s /var/lib/rancher/rke2/agent/etc/crictl.yaml /etc/crictl.yaml
export PATH=/var/lib/rancher/rke2/bin:$PATH
echo "export PATH=/var/lib/rancher/rke2/bin:$PATH" >> $HOME/.bash_profile
echo "alias oc=/var/lib/rancher/rke2/bin/kubectl" >> $HOME/.bash_profile

else

cat << EOF >  /etc/rancher/rke2/config.yaml
server: https://$MASTERIP:9345
token: pkls-secret
node-label:
- "region=worker"
EOF

curl -sfL https://get.rke2.io | INSTALL_RKE2_CHANNEL=v$K8S_VER_MJ INSTALL_RKE2_TYPE="agent" sh -
systemctl enable rke2-agent.service
systemctl start rke2-agent.service
echo "Check another window for Container UP"
sleep 20
ln -s /var/lib/rancher/rke2/agent/etc/crictl.yaml /etc/crictl.yaml
export PATH=/var/lib/rancher/rke2/bin:$PATH
echo "export PATH=/var/lib/rancher/rke2/bin:$PATH" >> $HOME/.bash_profile
exit

fi

kubectl get nodes

#MASTER=`kubectl get nodes | grep control-plane | awk '{print $1}'`
#kubectl taint nodes $MASTER node-role.kubernetes.io/control-plane-
#kubectl get nodes -o json | jq .items[].spec.taints

# Setup Ingress
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/deploy.yaml
sed -i -e 's\      #hostNetwork: true\      hostNetwork: true\g' deploy.yaml
kubectl create -f deploy.yaml
sleep 10
kubectl scale --replicas=2 deployment/ingress-nginx-controller -n ingress-nginx

# Check for Ingress POD UP
echo "Waiting for Ingress POD ready .."
sleep 10
INGPOD=`kubectl get pod -n ingress-nginx -o wide | grep ingress-nginx-controller | grep $(kubectl get no | grep control-plane | awk '{print $1}') | awk '{print $1}'`
kubectl wait pods/$INGPOD --for=condition=Ready --timeout=5m -n ingress-nginx

# Setup Monitoring
wget -q https://raw.githubusercontent.com/cloudcafetech/AI-for-K8S/main/kubemon.yaml
wget -q https://github.com/cloudcafetech/kubesetup/raw/master/monitoring/dashboard/pod-monitoring.json
wget -q https://github.com/cloudcafetech/kubesetup/raw/master/monitoring/dashboard/kube-monitoring-overview.json
sed -i "s/34.125.24.130/$PUBIPM/g" kubemon.yaml
kubectl create ns monitoring
kubectl create configmap grafana-dashboards -n monitoring --from-file=pod-monitoring.json --from-file=kube-monitoring-overview.json
#kubectl create -f kubemon.yaml -n monitoring

# Setup Logging
wget -q https://raw.githubusercontent.com/cloudcafetech/kubesetup/master/logging/kubelog.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/kubesetup/master/logging/loki.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/kubesetup/master/logging/promtail.yaml
kubectl create ns logging
kubectl create secret generic loki -n logging --from-file=loki.yaml
#kubectl create -f kubelog.yaml -n logging
#kubectl delete ds loki-fluent-bit-loki -n logging
#kubectl create -f promtail.yaml -n logging

# Helm Setup
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

### AD Integration
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/ad-integration.sh
chmod 755 ad-integration.sh
#./ad-integration.sh

# Setup K8SGPT
if [[ "$OS" == "Ubuntu" ]]; then
 curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.3.21/k8sgpt_amd64.deb 
 sudo dpkg -i k8sgpt_amd64.deb
else
 curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.3.21/k8sgpt_amd64.rpm
 sudo rpm -ivh -i k8sgpt_amd64.rpm
fi

# Install krew
set -x; cd "$(mktemp -d)" &&
OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
KREW="krew-${OS}_${ARCH}" &&
curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
tar zxvf "${KREW}.tar.gz" &&
./"${KREW}" install krew
  
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Install kubectl plugins using krew
kubectl krew install modify-secret
kubectl krew install ctx
kubectl krew install ns
kubectl krew install oidc-login

echo 'export PATH="${PATH}:${HOME}/.krew/bin"' >> /root/.bash_profile
