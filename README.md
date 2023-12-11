# Kubernetes Dashboard Active Directory Integration

## Setup LDAP Server

#### Run LDAP Server
```
apt install ldap-utils -y
HIP=`ip -o -4 addr list enp1s0 | awk '{print $4}' | cut -d/ -f1`

docker run --name ldap-server -p 389:389 -p 636:636 \
--env LDAP_TLS_VERIFY_CLIENT=try \
--env LDAP_ORGANISATION="Cloudcafe Org" \
--env LDAP_DOMAIN="cloudcafe.org" \
--env LDAP_ADMIN_PASSWORD="StrongAdminPassw0rd" \
--detach osixia/openldap:latest
```

#### Add LDAP User & Group 
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/ldap-records.ldif
ldapadd -x -H ldap://$HIP -D "cn=admin,dc=cloudcafe,dc=org" -w StrongAdminPassw0rd -f ldap-records.ldif
```

#### LDAP query (test)
```ldapsearch -x -H ldap://$HIP -D "cn=admin,dc=cloudcafe,dc=org" -b "dc=cloudcafe,dc=org" -w "StrongAdminPassw0rd"```

## Create K8S Cluster

https://killercoda.com/playgrounds/scenario/kubernetes

### Setup Ingress
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/deploy.yaml
kubectl create -f deploy.yaml
```

### Generate Certificate 
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/certgen.sh
chmod 755 certgen.sh
./certgen.sh
```

### Install DEX [OpenID Connect (OIDC)]
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dex-ldap-cm.yaml
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/dex.yaml
kubectl create -f dex-ldap-cm.yaml
kubectl create -f dex.yaml
```

#### You can check if Dex is deployed properly by browsing 
```
curl https://auth.172.30.2.2.nip.io:30443/.well-known/openid-configuration  --cacert ssl/ca.crt
curl https://auth.172.30.2.2.nip.io:30443/auth --cacert ssl/ca.crt
```

### Install Oauth2 Proxy [Authentication using Providers (LDAP,AD etc)]
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/oauth-proxy.yaml
kubectl create -f oauth-proxy.yaml
```
