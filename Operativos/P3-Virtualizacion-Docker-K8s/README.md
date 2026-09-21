# P3 — Lightweight virtualisation with Docker and Kubernetes

Containers as an operating-systems topic: how a kernel isolates groups of
processes, and what an orchestrator adds on top. The practice runs on a Debian
VM and goes from a bare `docker run` to a WordPress stack deployed
declaratively on a Kubernetes cluster.

## Contents

| Path | What it is |
|---|---|
| [`Practice_3_Virtualization_Docker_Kubernetes_Guillermo_Aladro_Abad.pdf`](Practice_3_Virtualization_Docker_Kubernetes_Guillermo_Aladro_Abad.pdf) | Full report: the procedure step by step, with the configuration files as an appendix |
| [`docker/install-docker.sh`](docker/install-docker.sh) | Question 1 — containerd + Docker installation on Debian, as root |
| [`docker/runbook.md`](docker/runbook.md) | Questions 1–14 — container lifecycle, images, volumes, ports, cgroup limits, WordPress by hand |
| [`docker/wordpress.yaml`](docker/wordpress.yaml) | Question 13 — the WordPress + MariaDB stack as a Compose file |
| [`kubernetes/runbook.md`](kubernetes/runbook.md) | Questions 15–27 — minikube, pods, services, persistent volumes, kustomize |
| [`kubernetes/nginx.yaml`](kubernetes/nginx.yaml) | Questions 18/20/23 — nginx pod and the ClusterIP service that exposes it |
| [`kubernetes/ubuntu.yaml`](kubernetes/ubuntu.yaml) | Questions 21/25 — auxiliary pod with a PersistentVolumeClaim |
| [`kubernetes/kustomization.yaml`](kubernetes/kustomization.yaml) | Question 26 — WordPress on Kubernetes with a generated Secret |

## What the practice shows

**Isolation is a kernel feature, not a machine.** A container is a group of
processes with its own namespaces — filesystem, process table, network stack,
users — and a cgroup that caps what it may consume. `docker exec` into a
container and `ps ax`, `df` and `ifconfig` all describe a world of their own,
yet the kernel underneath is the host's. That is the whole difference against a
virtual machine: no second kernel, no hypervisor, start-up in milliseconds, at
the cost of portability across operating systems.

**Nothing persists unless you say so.** A container's writable layer dies with
it. Durable state has to be attached explicitly: a host directory or a named
volume in Docker, a PersistentVolumeClaim in Kubernetes. The claim is the
interesting part — the pod asks for 100 MiB with an access mode and never names
a disk, and a provisioner satisfies it with whatever the cluster has.

**Configuration is injected, not baked in.** The same `mariadb` and `wordpress`
images become this deployment through environment variables, published ports
and mounted volumes. In Kubernetes the same role is played by ConfigMaps,
Secrets and env definitions, which is what lets one image serve every
environment.

**Imperative versus declarative.** The Docker half issues commands: run this,
stop that. The Kubernetes half declares an end state and lets the control plane
reach it. Changing the nginx image tag and re-applying the file is enough for
the cluster to destroy the old pod and schedule a new one, and a Deployment
keeps doing that on its own — if a pod dies or its node restarts, another is
created to match the declared state.

**Naming is what makes a cluster usable.** Pod IPs are neither routable from
outside nor stable across restarts, and a pod name is not a DNS record.
A Service provides the stable name and virtual IP, and it binds to pods through
label selectors, so the set of pods behind a name can change freely. ClusterIP
is internal; reaching the application from outside needs NodePort, LoadBalancer
or an Ingress — which is exactly why the WordPress example has to be switched
from LoadBalancer to NodePort to work on minikube.

## Notes

The commands and manifests here follow the practice statement; the YAML files
are the final versions of the objects it builds up across several questions
(the nginx pod, for instance, appears first without labels and later with the
service attached). Nothing here is a submission: the practice is assessed in a
lab test, not with a report.
