## K8S audit log enable
Kubernetes audit logs are disabled by default, which means that Kubernetes does not record the actions that are performed on your cluster.

### Create the audit-policy

```
wget -q https://raw.githubusercontent.com/kubernetes/website/main/content/en/examples/audit/audit-policy.yaml
mv audit-policy.yaml /etc/kubernetes/
```

### Edit apiserver manifest (/etc/kubernetes/manifests/kube-apiserver.yaml) as below 

 ```vi /etc/kubernetes/manifests/kube-apiserver.yaml```

 - By adding these two lines bellow the kube-apiserver command

```
    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
```

 - By adding these two lines bellow volumeMounts: section

```
    - mountPath: /etc/kubernetes/audit-policy.yaml
      name: audit
      readOnly: true
    - mountPath: /var/log/kubernetes/audit/
      name: audit-log
      readOnly: false
```

 - By adding these two lines bellow volumes: section

```
  - name: audit
    hostPath:
      path: /etc/kubernetes/audit-policy.yaml
      type: File
  - name: audit-log
    hostPath:
      path: /var/log/kubernetes/audit/
      type: DirectoryOrCreate
```

### Check apiserver running state

```kubectl get po -n kube-system```

### Ensure that audit logs are being generated

```tail -f /var/log/kubernetes/audit/audit.log```

REF (https://araji.medium.com/kubernetes-security-monitor-audit-logs-with-grafana-2ab0063906ce)
