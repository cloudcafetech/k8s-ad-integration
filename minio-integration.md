## Minio Integration

### Create Namespace, configmap from Dex CA certificate & tls certificate for ingress
```
kubectl create ns minio-store
kubectl create cm dex-cert --from-file=ssl/ca.crt -n minio-store
kubectl create secret tls minio --cert=ssl/tls.crt --key=ssl/tls.key -n minio-store
```

### Deployment
```
wget -q https://raw.githubusercontent.com/cloudcafetech/k8s-ad-integration/main/minio.yaml
kubectl create -f minio.yaml
```

### Create policy and should map with LDAP (cn) name as variable "MINIO_IDENTITY_OPENID_CLAIM_NAME" value name

- login minio with credencial & create policy (as below) with LDAP (cn) name.
- you can run as mc command also ```mc admin policy create prasen allaccess.json```

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::*"
      ]
    }
  ]
}
```

