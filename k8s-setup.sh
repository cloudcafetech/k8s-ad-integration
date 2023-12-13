#!/usr/bin/env bash
# Kubernetes host setup script using Kubeadm for Debian & Redhat distribution

PUBIPM=31.128.11.45
PUBIPN=21.20.11.46
K8S_VER=1.26.0-00

if [[ -n $(uname -a | grep -iE 'ubuntu|debian') ]]; then 
 OS=Ubuntu
 HIP=`ip -o -4 addr list enp1s0 | awk '{print $4}' | cut -d/ -f1`
else
 HIP=`ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1`
fi

if [[ "$K8S_VER" == "" ]]; then K8S_VER=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt | cut -d v -f2); fi
K8S_VER_MJ=$(echo "$K8S_VER" | cut -c 1-4)

# Disable swap
swapoff -a
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

cat <<EOF |sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf 
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

sysctl --system

## Installation based on OS

### For Debian distribution
if [[ "$OS" == "Ubuntu" ]]; then
 # Stopping and disabling firewalld by running the commands on all servers:
 systemctl stop ufw
 systemctl disable ufw
 # Install some of the tools, we’ll need on our servers.
 apt update
 apt install apt-transport-https ca-certificates gpg nfs-common curl wget git net-tools unzip jq zip nmap telnet dos2unix apparmor ldap-utils -y
 mkdir -m 755 /etc/apt/keyrings
 curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VER_MJ}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
 echo deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$K8S_VER_MJ/deb/ / | sudo tee /etc/apt/sources.list.d/kubernetes.list

 # Install Container Runtime, Kubeadm, Kubelet & Kubectl
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
 add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
 apt update
 rm -I /etc/containerd/config.toml
 apt install -y containerd.io
 apt install -y kubelet kubeadm kubectl
 apt-mark hold kubelet kubeadm kubectl

### For Redhat distribution

else
 # Stopping and disabling firewalld & SELinux
 systemctl stop firewalld
 systemctl disable firewalld
 setenforce 0
 sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
 # Install some of the tools, we’ll need on our servers.
 yum install -y git curl wget bind-utils jq httpd-tools zip unzip nfs-utils go nmap telnet dos2unix java-1.7.0-openjdk

# Add the kubernetes repository to yum so that we can use our package manager to install the latest version of kubernetes. 
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v$K8S_VER_MJ/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v$K8S_VER_MJ/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

 # Install Container Runtime, Kubeadm, Kubelet & Kubectl
 yum config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
 yum install -y yum-utils containerd.io && rm -I /etc/containerd/config.toml
 yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
fi

## Installation based on OS 

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml 
sed -i -e 's\            SystemdCgroup = false\            SystemdCgroup = true\g' /etc/containerd/config.toml

cat <<EOF | tee /etc/crictl.yaml
runtime-endpoint: "unix:///run/containerd/containerd.sock"
timeout: 0
debug: false
EOF

# After installing containerd, kubernetes tools  & enable the services so that they persist post reboots.
systemctl enable --now containerd; systemctl start containerd
#systemctl status containerd
systemctl enable --now kubelet; systemctl start kubelet
#systemctl status kubelet

# K8s images pull
kubeadm config images pull

# Uncomment next line (exit) for Node setup &  use join node command
#exit

# Setting up Kubernetes Master using Kubeadm
kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all 

cp /etc/kubernetes/admin.conf $HOME/
chown $(id -u):$(id -g) $HOME/admin.conf
export KUBECONFIG=$HOME/admin.conf
echo "export KUBECONFIG=$HOME/admin.conf" >> $HOME/.bash_profile
echo "alias oc=/usr/bin/kubectl" >> /root/.bash_profile

mkdir setup-files
cd setup-files

wget -q https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl create -f kube-flannel.yml

sleep 20
kubectl get nodes

MASTER=`kubectl get nodes | grep control-plane | awk '{print $1}'`
kubectl taint nodes $MASTER node-role.kubernetes.io/control-plane-
kubectl get nodes -o json | jq .items[].spec.taints

# Setup Ingress
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/deploy.yaml
sed -i -e 's\      #hostNetwork: true\      hostNetwork: true\g' deploy.yaml
kubectl create -f deploy.yaml

# Setup Metric Server
#kubectl apply -f https://raw.githubusercontent.com/cloudcafetech/kubesetup/master/monitoring/metric-server.yaml

# Setup Monitoring
#wget -q https://raw.githubusercontent.com/cloudcafetech/AI-for-K8S/main/kubemon.yaml
#sed -i "s/34.125.24.130/$HIP/g" kubemon.yaml
#kubectl create ns monitoring
#kubectl create -f kubemon.yaml -n monitoring

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

kubectl get nodes

# Setup K8SGPT
if [[ "$OS" == "Ubuntu" ]]; then
 curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.3.21/k8sgpt_amd64.deb 
 sudo dpkg -i k8sgpt_amd64.deb
else
 curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.3.21/k8sgpt_amd64.rpm
 sudo rpm -ivh -i k8sgpt_amd64.rpm
fi

#exit

### AD Integration

# Setup K8s Dashboard
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-ui.yaml
kubectl apply -f dashboard-ui.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dashboard/dashboard-ing.yaml
sed -i -e 's\172.30.2.2\$PUBIPM\g' dashboard-ing.yaml
kubectl create -f dashboard-ing.yaml

# Certificate Generate
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/certgen.sh
sed -i -e 's\172.30.2.2\$PUBIPN\g' certgen.sh
sed -i -e 's\172.30.1.2\$PUBIPM\g' certgen.sh
chmod 755 certgen.sh
./certgen.sh

# Dex Deployment
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dex-ldap-cm.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dex.yaml
sed -i -e 's\172.30.2.2\$PUBIPM\g' dex-ldap-cm.yaml
sed -i -e 's\172.30.1.2\$PUBIPM\g' dex-ldap-cm.yaml
sed -i -e 's\:30443\\g' dex-ldap-cm.yaml
sed -i -e 's\172.30.2.2\$PUBIPM\g' dex.yaml
kubectl create -f dex-ldap-cm.yaml
kubectl create -f dex.yaml

# Oauth Deployment
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/oauth-proxy.yaml
sed -i -e 's\:30443\\g' oauth-proxy.yaml
sed -i -e 's\172.30.2.2\$PUBIPM\g' oauth-proxy.yaml
kubectl create -f oauth-proxy.yaml

# Create the role binding for different users
kubectl create rolebinding pkar-admin --clusterrole=admin --user=pkar
kubectl create rolebinding mkar-view-default --clusterrole=view --user=mkar -n default
kubectl create rolebinding read-only-user-view --clusterrole=view --user=read-only-user

# Copy Certificate & edit the Kubernetes API configuration
cp ssl/ca.crt /etc/kubernetes/pki/dex-ca.crt

echo "Follow URL - https://github.com/cloudcafetech/k8s-ad-integration/tree/main#modify-api-server-manifest-in-all-master-nodes"