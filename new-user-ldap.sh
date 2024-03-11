#!/usr/bin/env bash
# New users insert in LDAP

LDAPIP=172.168.1.1

# Checking current number of records in LDAP
echo "Checking current number of records in LDAP"
ldapsearch -x -H ldap://$LDAPIP -D "cn=admin,dc=cloudcafe,dc=org" -b "dc=cloudcafe,dc=org" -w "StrongAdminPassw0rd" | grep num

# Download LDAP new user ldif file & insert in LDAP
echo "Adding new user in LDAP .."
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/new-add-user.ldif
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/add-user-in-grp.ldif
ldapadd -x -H ldap://$LDAPIP -D "cn=admin,dc=cloudcafe,dc=org" -w StrongAdminPassw0rd -f new-add-user.ldif
ldapadd -x -H ldap://$LDAPIP -D "cn=admin,dc=cloudcafe,dc=org" -w StrongAdminPassw0rd -f add-user-in-grp.ldif

# After adding number of records in LDAP
echo "After adding number of records in LDAP"
ldapsearch -x -H ldap://$LDAPIP -D "cn=admin,dc=cloudcafe,dc=org" -b "dc=cloudcafe,dc=org" -w "StrongAdminPassw0rd" | grep num

# Create the role binding for new users
echo "Creating roles for new user in K8s .."
kubectl create rolebinding titli-view-default --clusterrole=view --user=titlikar@cloudcafe.org -n default
kubectl create rolebinding rajat-admin-default --clusterrole=admin --user=rajatkar@cloudcafe.org -n default
