# Instant-Infra

Kubernetes-native Internal Developer Platform (IDP) to eliminate TicketOps.

## Quick Start

```bash
cd terraform
terraform init
terraform apply
```

## GitOps Flow

- ArgoCD bootstraps from `gitops/bootstrap/root.yaml`.
- Platform components live in `gitops/platform/`.
- Workloads live in `gitops/workloads/`.

## Safety

- All infra changes via Git.
- No `kubectl apply` or `helm install` in production.

## Cost Awareness

Running EKS + NAT Gateway + LB incurs monthly cost. Destroy when not in use.
