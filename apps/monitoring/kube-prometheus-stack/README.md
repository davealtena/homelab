# links

https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack

# Troubleshooting

| alertmanagerconfigs.monitoring.coreos.com" is invalid: metadata.annotations: Too long: must have at most

Add `ServerSideApply=true`

| Error creating: pods "kube-prometheus-stack-prometheus-node-exporter-phtxc" is forbidden: violates PodSecurity "baseline:latest": host namespaces (hostNetwork=true, hostPID=true), hostPath volumes (volumes "proc", "sys", "root"), hostPort (container "node-exporter" uses hostPort 9100)

https://www.talos.dev/v1.7/kubernetes-guides/configuration/pod-security/

Add label to your namespace:
```
metadata:
  name: narf
  labels:
    pod-security.kubernetes.io/enforce: privileged
```