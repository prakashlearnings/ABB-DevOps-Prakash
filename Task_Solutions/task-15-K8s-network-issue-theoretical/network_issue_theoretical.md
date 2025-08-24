# AKS Network Issue: Pods Cannot Communicate with External Services

---

## Description of the Issue

**Issue:**  
Pods in the AKS cluster are unable to reach external internet services (e.g., `curl https://www.google.com` fails). Internal communication between pods is working fine.

**Impact:**  
- Applications dependent on external APIs or services fail.
- CI/CD deployments that require external connections may fail.
- Monitoring and alerting services that rely on external endpoints stop working.

**Environment:**  
- AKS Cluster: `prod-aks-cluster`
- Namespace: `app-namespace`
- Pods: `webapp-frontend`, `webapp-backend`
- Node pool: `Standard_D2s_v3`

---

## Investigation Steps

1. **Check pod status and events:**

```bash
kubectl get pods -n app-namespace
kubectl describe pod webapp-frontend -n app-namespace
```

**Sample `kubectl describe pod` output:**
```
Name:         webapp-frontend-6d4b7c7f6f-abcde
Namespace:    app-namespace
Node:         aks-nodepool1-12345678-0/10.240.0.4
Status:       Running
IP:           10.244.0.5
Containers:
  webapp-frontend:
    Container ID:   docker://abcdef123456
    Image:          myregistry/webapp:1.0
    State:          Running
    Ready:          True
    Restart Count:  0
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  20m   default-scheduler  Successfully assigned app-namespace/webapp-frontend-6d4b7c7f6f-abcde to aks-nodepool1-12345678-0
```

2. **Check logs from the pod:**

```bash
kubectl logs webapp-frontend-6d4b7c7f6f-abcde -n app-namespace
```

**Sample pod logs (connection failures):**
```
2025-08-24T10:15:23Z ERROR Failed to fetch data from https://api.external-service.com: getaddrinfo ENOTFOUND api.external-service.com
2025-08-24T10:15:23Z ERROR Network unreachable
```

3. **Test connectivity from the pod:**

```bash
kubectl exec -it webapp-frontend-6d4b7c7f6f-abcde -n app-namespace -- ping 8.8.8.8
kubectl exec -it webapp-frontend-6d4b7c7f6f-abcde -n app-namespace -- curl https://www.google.com
```

**Output:**
```
ping: connect: Network is unreachable
curl: (6) Could not resolve host: www.google.com
```

4. **Check node network configuration and NAT rules:**

```bash
kubectl get nodes -o wide
az network vnet list --resource-group aks-network-rg
az network vnet subnet show --resource-group aks-network-rg --vnet-name aks-vnet --name aks-subnet
```

---

## Root Cause

- The **AKS cluster node pool subnet** did not have proper **NAT gateway** or **outbound internet access** configured.
- Pods were running in a **private subnet** without NAT or load balancer outbound rules.

---

## Resolution Steps

1. **Create or assign a NAT gateway:**

```bash
az network nat gateway create \
  --resource-group aks-network-rg \
  --name aks-nat-gateway \
  --public-ip-addresses aks-nat-ip \
  --idle-timeout 10
```

2. **Associate NAT gateway with the AKS subnet:**

```bash
az network vnet subnet update \
  --resource-group aks-network-rg \
  --vnet-name aks-vnet \
  --name aks-subnet \
  --nat-gateway aks-nat-gateway
```

3. **Verify connectivity from a pod:**

```bash
kubectl exec -it webapp-frontend-6d4b7c7f6f-abcde -n app-namespace -- curl https://www.google.com
```

**Output (success):**
```
<!doctype html><html>...Google homepage HTML...</html>
```

4. **Optional:** Update AKS deployment to ensure future nodes inherit the subnet/NAT configuration.

---

## Logs (for documentation)

**Pod describe:**
```
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  20m   default-scheduler  Successfully assigned app-namespace/webapp-frontend-6d4b7c7f6f-abcde to aks-nodepool1-12345678-0
  Normal  Pulled     20m   kubelet, aks-nodepool1-12345678-0  Container image "myregistry/webapp:1.0" already present on machine
  Normal  Created    20m   kubelet, aks-nodepool1-12345678-0  Created container webapp-frontend
  Normal  Started    20m   kubelet, aks-nodepool1-12345678-0  Started container webapp-frontend
```

**Pod logs before fix:**
```
ERROR Failed to fetch data from https://api.external-service.com: getaddrinfo ENOTFOUND api.external-service.com
ERROR Network unreachable
```

**Pod logs after fix:**
```
INFO Successfully connected to https://api.external-service.com
INFO Data fetched and processed.
```

---

## Key Takeaways

- Pods in **private subnets** require **outbound internet access** via NAT gateway or load balancer.
- `kubectl exec` and `curl` are handy for testing network connectivity from within pods.
- Always verify **subnet and node pool network configuration** in AKS for external connectivity.

