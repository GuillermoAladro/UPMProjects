# Kubernetes runbook — Questions 15 to 27

minikube runs a single-node cluster on top of the Docker installed in the
previous section, so the VM needs at least 2 CPUs and 4 GiB of RAM.

## Installing and checking minikube (Q15 – Q17)

```bash
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
minikube start
sudo apt install kubectl

kubectl get nodes -o wide
kubectl get namespaces
kubectl get all
minikube --help
```

`kubectl` authenticates against the API server with the credentials minikube
writes to `~/.kube/config`.

## Pods (Q18 – Q21)

```bash
kubectl apply -f nginx.yaml     # see nginx.yaml in this folder

kubectl get pods
kubectl get pod/nginx -o yaml   # the object as the cluster stores it
kubectl describe pod/nginx      # events: scheduling, image pull, start
kubectl exec -it pod/nginx -- bash

# Port forwarding is for testing only
kubectl port-forward pod/nginx 8080:80
curl -D - http://localhost:8080

# Port 80 is privileged, so this form needs sudo and an explicit kubeconfig
sudo kubectl --kubeconfig=$HOME/.kube/config port-forward pod/nginx 80:80
```

Question 20 changes `image: nginx:1.25` to `nginx:1.29` in the YAML and
re-applies it. The declarative model shows itself here: nothing describes *how*
to upgrade, only the desired end state, and the control plane destroys the old
pod and creates a new one. Not every field can be modified in place — for many
of them the object has to be deleted and recreated.

Question 21 adds the auxiliary Ubuntu pod, declared in
[`ubuntu.yaml`](ubuntu.yaml).

## Services (Q22 – Q24)

Question 22 is a list of things that do **not** work, and each failure has its
reason:

| Attempt | Result |
|---|---|
| `curl http://<pod IP>:80` from the host | no route — pod IPs live inside the cluster network |
| `curl http://localhost:80` from the Ubuntu pod | nothing listening — localhost is that pod's own namespace |
| `curl http://nginx:80` from the Ubuntu pod | name does not resolve — a pod name is not a DNS record |
| `curl http://<pod IP>:80` from the Ubuntu pod | works, but the address changes whenever the pod is recreated |

The fix is the Service in `nginx.yaml`: it gives the workload a stable name and
virtual IP, and binds to pods by **label**, not by name.

```bash
kubectl apply -f nginx.yaml
kubectl get services
kubectl exec -it pod/base -- bash
curl http://servidorweb:80          # now it resolves and connects
```

Cleanup (Q24), either object by object or through the files that declared them:

```bash
kubectl delete pod/nginx
kubectl delete pod/base
kubectl delete service/servidorweb
# or
kubectl delete -f nginx.yaml -f ubuntu.yaml
```

## Persistent storage (Q25)

```bash
kubectl apply -f ubuntu.yaml
kubectl get pvc
kubectl get pv
kubectl exec -it base -- bash
df                                  # /datos is backed by the claim
```

The pod asks for storage through a PersistentVolumeClaim and never names a disk;
a CSI provisioner satisfies the claim. In minikube that is the hostpath
provisioner writing under
`/var/lib/docker/volumes/minikube/_data/hostpath-provisioner`, while a real
cluster would bind NFS, Ceph or EBS behind the same claim.

## Declarative applications (Q26 – Q27)

```bash
curl -LO https://k8s.io/examples/application/wordpress/mysql-deployment.yaml
curl -LO https://k8s.io/examples/application/wordpress/wordpress-deployment.yaml

# minikube has no cloud load balancer behind it
sed -i '' 's/LoadBalancer/NodePort/' wordpress-deployment.yaml

kubectl apply -k ./                 # see kustomization.yaml
minikube service wordpress --url
```

`kustomization.yaml` turns the database password into a generated Secret instead
of a literal in the manifests, and applies both deployments as one unit.
