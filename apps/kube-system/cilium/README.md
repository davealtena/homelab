# Install cilium

Install cilium into an empty cluster like this. Note that it is normal for talas to report "notready" on `k get nodes' at this stage:  
`kubectl kustomize --enable-helm apps/cilium | kubectl apply -f -`

After this, install argocd into the cluster in a similar way.

# test l2 ingress

kubectl describe l2announcement
kubectl get ippools
kubectl get CiliumL2AnnouncementPolicy
kubectl get leases -n kube-system

# api gateway checks
```
kubectl describe gatewayclass cilium
echo "---"
kubectl get gateway -A
echo "---"
kubectl get service -A
echo "---"
kubectl describe gateway gateway-internal -n argocd
echo "---"
kubectl get httproute -A
echo "---"
kubectl describe httproute http-argocd-1 -n argocd
echo "---"
kubectl get svc -A | grep LoadBalancer
```

# troubleshooting

## Waiting for controller
check the `stern -n kube-system controller --tail 25`
And `kubectl describe gateway argocd-gateway -n gateway`

Check that you have a gatewayclass: `kubectl describe gatewayclasses.gateway.networking.k8s.io cilium`

### soliutions

 * you might be running cilium 1.15 but using the gatewayAPI 1.1 CRDs
 * Restart the cilium operator

 # l2announcements request IP

 https://docs.cilium.io/en/latest/network/lb-ipam/#requesting-ips

```
kind: Service
apiVersion: v1
metadata:
  annotations:
    lbipam.cilium.io/ips: "192.168.178.91"
    lbipam.cilium.io/sharing-key: prometheus
```