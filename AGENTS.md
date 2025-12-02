# Project Title: The "Instant-Infra" Platform

This document serves as a reference and roadmap for the "Instant-Infra" project. It outlines the philosophy, architecture, tool stack, and implementation phases.

## 1. Executive Summary & Philosophy

**The Problem:** In traditional environments, developers are blocked by "TicketOps." To deploy a new app, they need to wait for Ops to provision an S3 bucket, a database, and compute resources. This causes friction, delay, and "Shadow IT."

**The Solution:** Build a Kubernetes-Native Platform that allows developers to self-provision secure, compliant, and cost-effective AWS infrastructure using simple "Golden Path" templates.

**The Philosophy:**

1.  **Intent-Based:** Developers should define what they need (e.g., "A web app with a database"), not how to build it.
2.  **Vending Machine Model:** Ops builds the "Vending Machine," not hand-deliver the snacks.
3.  **GitOps:** Infrastructure should be ephemeral, reproducible, and managed entirely via Git.
4.  **Automated Security:** Security should be automated (Identity) and enforced (Policy), not manual.

## 2. Architecture Overview

The system is a "Layer Cake" architecture where each tool solves a specific layer of the platform stack.

*   **Layer 1: The Foundation (EKS + IAM)**
    *   Manual setup of the AWS Elastic Kubernetes Service and OIDC Providers for identity.
*   **Layer 2: The GitOps Engine (ArgoCD)**
    *   The "Brain" that ensures the cluster always matches the Git repository state.
*   **Layer 3: The Supply Chain (ACK + Karpenter)**
    *   **ACK:** Talks to AWS APIs to create Cloud Resources (S3, RDS).
    *   **Karpenter:** Talks to EC2 APIs to create Compute Nodes (Spot Instances).
*   **Layer 4: The Abstraction (KRO)**
    *   The "Interface" that wraps complex configs into simple Developer APIs.
*   **Layer 5: The Security (Vault + ESO + Kyverno)**
    *   Manages Secrets and enforces Policy governance.
*   **Layer 6: Day-2 Ops (Observability + Networking)**
    *   Handles Logs, DNS, and SSL automatically.

## 3. The Tool Stack (Tech Spec)

| Component | Tool | Role | Why Manual Setup? |
| :--- | :--- | :--- | :--- |
| **Compute** | AWS EKS | The Container Orchestrator | To learn VPC networking and OIDC. |
| **GitOps** | ArgoCD | Continuous Delivery | To master the "App of Apps" pattern. |
| **Cloud Infra** | ACK (AWS Controllers for K8s) | Infrastructure as Code (K8s style) | To master IRSA (IAM Roles for Service Accounts). |
| **Scaling** | Karpenter | Just-in-Time Node Autoscaling | To master AWS Spot Instances and Cost Optimization. |
| **API/Templates** | KRO (Kubernetes Resource Orchestrator) | Custom Resource Definitions (CRDs) | To demonstrate "Platform Engineering" (Golden Paths). |
| **Secrets** | Vault + ESO (External Secrets Operator) | Secrets Management | To demonstrate "Secret Zero" architecture. |
| **Policy** | Kyverno | Admissions Controller | To demonstrate Governance and Compliance. |
| **Observability** | OpenTelemetry + Loki + Grafana | Logs & Metrics | To demonstrate modern, vendor-neutral observability. |

## 4. Detailed Implementation Roadmap

### Phase 1: The "Bare Metal" Foundation (Terraform)
*   **Goal:** A working EKS Cluster with OIDC enabled.
*   **Steps:**
    1.  Write Terraform to create a VPC, Subnets (Public/Private), and Route Tables.
    2.  Write Terraform for the EKS Control Plane.
    3.  **Critical:** Enable the OIDC Identity Provider in Terraform. This is required for pods to assume IAM roles later.
    4.  Create a basic Managed Node Group (just 1 small node) to host the system tools (ArgoCD).

### Phase 2: The Brain (ArgoCD)
*   **Goal:** A cluster that manages itself.
*   **Steps:**
    1.  Install ArgoCD using Helm (manual CLI install first).
    2.  Create a Git Repo `platform-infra`.
    3.  Configure ArgoCD to watch this repo.
    4.  Create the "App of Apps" structure (a root Application that points to folders for Karpenter, ACK, etc.).

### Phase 3: The Supply Chain (ACK & Karpenter)
*   **Goal:** The cluster can create AWS resources and EC2 nodes.
*   **Steps (The "Hard" Part - IAM):**
    1.  **ACK S3 Setup:**
        *   Create an IAM Role `ACK-S3-Role` with `AmazonS3FullAccess`.
        *   Edit the Trust Policy to allow the `ack-s3-controller` ServiceAccount to assume it (via OIDC).
        *   Deploy the ACK S3 Controller (via ArgoCD) and annotate the ServiceAccount with the Role ARN.
    2.  **Karpenter Setup:**
        *   Create `KarpenterControllerRole` (IRSA) allowing `ec2:CreateFleet`.
        *   Create `KarpenterNodeRole` (Instance Profile) for the new worker nodes.
        *   Deploy Karpenter (via ArgoCD).
        *   Define a `NodePool` (YAML) telling Karpenter to use Spot Instances (t3.medium, t3.large).

### Phase 4: The Abstraction (KRO)
*   **Goal:** Create the "Simple Button" for developers.
*   **Steps:**
    1.  Deploy KRO (via ArgoCD).
    2.  Create a ResourceGroup named `SuperApp`.
    3.  Define the Template Logic:
        *   **Input:** name, image, database (bool).
        *   **Output:** Generates an ACK Bucket + ACK RDSInstance + Kubernetes Deployment + Service.

### Phase 5: Security & Governance
*   **Goal:** Secure the platform without blocking developers.
*   **Steps:**
    1.  **Vault:** Deploy HashiCorp Vault. Enable the Kubernetes Auth Method.
    2.  **ESO:** Deploy External Secrets Operator. Configure a SecretStore pointing to Vault.
    3.  **Kyverno:** Deploy Kyverno. Write a ClusterPolicy that blocks any Pod request that asks for more than 4GB RAM (Cost Control).

### Phase 6: The Developer Experience (Day 2 Ops)
*   **Goal:** URLs, Logs, and Automation.
*   **Steps:**
    1.  **Networking:** Deploy Nginx Ingress + ExternalDNS (with Route53 permissions) + Cert-Manager.
    2.  **Observability:** Deploy the OpenTelemetry Operator. Configure a Collector to scrape logs and send them to Loki.
    3.  **The Code Repo:** Create a sample "Hello World" Python app repo with a GitHub Action.
        *   **Action:** Builds Docker image -> Pushes to ECR -> Updates the Helm/Kustomize tag in the Git repo.

## 5. The "Developer Workflow" (How it is used)

**Scenario:** Dave (Dev) creates a new repo from your template.

1.  He edits `app.yaml`:
    ```yaml
    kind: SuperApp
    metadata: { name: "marketing-site" }
    spec:
      image: "marketing:v1"
      size: "medium"
      database: true
    ```
2.  Dave runs `git push`.
3.  ArgoCD syncs the YAML.
4.  KRO translates it.
5.  ACK provisions the Database.
6.  Karpenter provisions a Spot Instance.
7.  ESO injects the Database Password.
8.  ExternalDNS creates `marketing.dev.company.com`.
9.  Dave receives a Slack notification: "Your app is live."

## 6. Key Resume Keywords Generated

*   **Platform Engineering:** IDP, Golden Paths, KRO.
*   **AWS Cloud:** EKS, IAM, OIDC, IRSA, Spot Instances.
*   **Kubernetes:** Operators, CRDs, Helm, Kustomize.
*   **GitOps:** ArgoCD, Drift Detection.
*   **Security:** HashiCorp Vault, External Secrets, Kyverno, Policy-as-Code.
*   **Observability:** OpenTelemetry, Loki, Grafana.

## 7. Next Step: Getting Started

**Action Item:** Initialize your Terraform repository.

**First Goal:** Get a "Naked" EKS Cluster running with OIDC enabled.


