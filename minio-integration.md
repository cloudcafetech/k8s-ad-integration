## Minio Integration

### Create local storage provitioners
```
wget -q https://raw.githubusercontent.com/cloudcafetech/rke2-airgap/main/local-path-storage.yaml
kubectl create -f local-path-storage.yaml
```

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

### Create policy and should map with LDAP (cn) groups as variable "MINIO_IDENTITY_OPENID_CLAIM_NAME" value groups

- login minio with credencial & create policy (as below) with LDAP (cn) groups.
- you can run as mc command also ```mc admin policy create admins/developers allaccess.json```

- For bucket creation policy (Group name - *admins*)
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

- For bucket view policy (Group name - *developers*)
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::*"
            ]
        }
    ]
}
```

