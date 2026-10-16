# Instant-Infra

A self-service Internal Developer Platform (IDP): a "vending machine" where a
developer asks for an app environment and gets one, with no ticket to a
platform team.

> **Status: on ice (2026-10-16).** Design and partial code only. **Never
> deployed. Do not `terraform apply` it as-is**: it creates billable AWS
> resources (EKS, NAT gateway, load balancers) and does not come up cleanly.

## Why it's on ice

- **Not what junior DevOps roles need.** An IDP is platform-team work for
  companies with many dev teams. Linux, Kubernetes, CI/CD, Terraform and one
  cloud matter more right now.
- **Unstable foundations.** Key pieces are pre-1.0 (KRO v0.9; OCI Service
  Operator v2 is alpha and needs OLM). Time would go to fighting tools, not learning.
- **Hard to prove.** Without real developers using it, a self-service platform
  is a demo of plumbing, not of value.
- **Better uses of time.** Certifications (LFCS, CKA) and finishing the
  projects that already work come first.

## The idea

An IDP has four layers. A developer only touches the top one:

| Layer | Job | Tools considered |
|---|---|---|
| **Interface** (the button) | Self-service UI or CLI where a dev orders an environment | custom UI, Backstage templates |
| **API** (the menu) | One simple resource, e.g. `WebApp: name + image`, that expands into everything needed | KRO `ResourceGraphDefinition` |
| **Controllers / sync** (delivery) | Turn requests into real resources, reviewed through Git | ArgoCD; cloud operators (ACK, OSOK) |
| **Runtime** | Where it all runs | EKS (v1), OKE (v2) |

v1 built from the bottom up and stalled before reaching the interface, which
was the part that mattered. If revived, start from the top.

## What's in this repo (v1, EKS)

- `terraform/`: VPC, EKS 1.34, a tainted system node group, IAM roles for
  service accounts (Karpenter, ACK S3, ALB controller, ExternalDNS), ArgoCD via Helm.
- `gitops/`: ArgoCD Applications for Karpenter, ACK S3, KRO, the AWS Load
  Balancer Controller, ExternalDNS, Kyverno, Trivy and Falco, plus a draft
  `SuperApp` definition and a demo workload.
- `AGENTS.md`: the original blueprint.

Known blockers, found in review and never fixed:

- ArgoCD has no toleration for the `CriticalAddonsOnly` taint on the only node
  group, so nothing schedules. The Helm provider isn't configured for the cluster either.
- Karpenter: `EC2NodeClass` uses the wrong API group, old `v1beta1` APIs, and an
  AL2 AMI that doesn't exist for EKS 1.34. There's no EKS access entry for its
  nodes, and the controller policy is missing instance-profile permissions.
- `root-app` doesn't recurse into `gitops/platform/` subfolders, nothing points
  at `gitops/workloads/`, and `root-app` is defined twice.
- The KRO definition uses outdated syntax (`${spec.x}` instead of
  `${schema.spec.x}`, `when` instead of `includeWhen`, an invalid schema `apiVersion`).
- OCI Helm charts (ECR) have no ArgoCD OCI repository configured.
- A single t3.medium can't fit the planned stack (17-pod limit).
- CI passes only because `kubeconform` skips every CRD.

## If revived: v2 direction (OKE, free tier)

Run it on the existing free OKE cluster (Arm A1 nodes), which already has
ArgoCD, Envoy Gateway and cert-manager. That removes the EKS cost and most of v1.

1. **Menu:** install KRO (`oci://registry.k8s.io/kro/charts/kro`; the image
   is multi-arch, so it runs on arm64). Define one API, `WebApp`: Deployment +
   Service + HTTPRoute + cert-manager Certificate. Pin the version; KRO is pre-1.0.
2. **Delivery:** ArgoCD from a GitOps repo, with the OCI Helm repo enabled.
3. **Button:** a small self-service UI that opens a pull request to the GitOps
   repo (reviewable and reversible), then shows status and the URL.
4. **First customer:** the personal website, deployed as a `WebApp`.
5. **Later, Oracle services through OSOK** (OCI Service Operator), for example
   an Always Free Autonomous Database or bucket. Before trying it:
   - confirm a published arm64 image exists;
   - accept the OLM requirement;
   - prefer a narrowly scoped user-principal secret over node-wide instance
     principal, in its own compartment;
   - **cost guardrails:** hard-code `isFreeTier: true` in the KRO definition,
     and set **compartment quotas** so Oracle itself rejects anything outside
     the free tier.

**Out of scope: kcp.** kcp gives many isolated teams cluster-like workspaces
on shared infrastructure. It is not the vending machine itself; it only
matters once there are multiple teams to isolate.

## Lessons

- Build the part users touch first; infrastructure underneath can start small.
- Pick a cheap runtime before designing around an expensive one.
- Green CI that skips validation is worse than no CI.
- Pre-1.0 tools need pinned versions and a reason to be in the stack.
