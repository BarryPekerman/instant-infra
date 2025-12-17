# Project Blueprint: The "Instant-Infra" Platform

**Current Status:** Foundation Phase (v0.2.0)
**Codebase Strategy:** Monorepo ("Physically United, Logically Divided")

---

## 1. The Goal
**"The Vending Machine for Cloud Infrastructure."**

We are building a Kubernetes-Native Internal Developer Platform (IDP) designed to eliminate "TicketOps."

*   **For the Developer:** They push a single file (`superapp.yaml`) to Git, and the platform automatically provisions a secure URL, a database, and an S3 bucket—no Jira tickets required.
*   **For the Business:** Velocity increases from days to minutes, while governance (security, compliance) is enforced automatically by the platform code.

---

## 2. The Toolchain (The "Resume Flex")

| Category | Tool | Why it’s here |
| :--- | :--- | :--- |
| **Engine** | AWS EKS (v1.33+) | The industry standard for container orchestration. |
| **IaC** | Terraform | Bootstraps the physical "Skeleton" (VPC, IAM, Cluster). |
| **GitOps** | ArgoCD | The "Brain" that ensures the cluster matches the Git state. |
| **Compute** | Karpenter | "Just-in-Time" Scaling. Replaces static ASGs with dynamic, cost-optimized provisioning. |
| **Cloud Link** | ACK (AWS Controllers) | Allows K8s to create AWS resources (S3, RDS) using YAML. |
| **Abstraction** | KRO | The "Secret Sauce." Bundles complex objects into a simple API (`kind: SuperApp`). |
| **Networking** | AWS LB Controller | Provisions real AWS Application Load Balancers (ALB) for Ingress. |
| **DNS** | ExternalDNS | Automatically updates Route53 for real URLs (`app.dev.company.com`). |
| **Secrets** | External Secrets Operator | Fetches secrets from AWS Secrets Manager (No keys in Git). |

---

## 3. The Repository Structure

```text
instant-infra/
├── .github/workflows/         # Automation (CI)
│   ├── infra-check.yaml       # Runs `terraform plan` on /terraform changes
│   └── gitops-lint.yaml       # Runs `kubeconform` on /gitops changes
│
├── terraform/                 # THE LIFEBOAT (Base Infrastructure)
│   ├── main.tf                # VPC, EKS Control Plane, OIDC
│   ├── iam.tf                 # IAM Roles for Service Accounts (IRSA)
│   └── nodes.tf               # Small static NodeGroup (Critical Addons Only)
│
└── gitops/                    # THE OCEAN (Platform & Apps)
    ├── bootstrap/             # ArgoCD "App of Apps" entry point
    │
    ├── platform/              # The "Machine Room"
    │   ├── karpenter/         # Provisioner & NodePool configs
    │   ├── ack/               # S3 & RDS Controllers
    │   ├── ingress/           # ALB Controller + ExternalDNS
    │   └── kro/               # ResourceGraphDefinition (SuperApp API)
    │
    └── workloads/             # The "Customers"
        └── superapp-demo/     # A sample application utilizing the platform
```

---

## 4. The Architecture ("Lifeboat vs. Ocean")

### Layer 1: The Lifeboat (Static & Safe)
*   **Managed by:** Terraform.
*   **Components:** VPC, Control Plane, "System Node Group" (2x t3.medium).
*   **Function:** Hosts the "Brains" (ArgoCD, Karpenter, CoreDNS). These nodes **never** scale to zero.
*   **Configuration:** Node Group tainted with `CriticalAddonsOnly=true:NoSchedule` to prevent user apps from landing here.
*   **Security:** EKS Access Entries for Auth.

### Layer 2: The Ocean (Dynamic & Scalable)
*   **Managed by:** Karpenter (via ArgoCD).
*   **Components:** Variable EC2 instances (Spot/On-Demand).
*   **Function:** Hosts the User Applications (`SuperApps`).
*   **Behavior:** Scales from 0 to 100+ nodes based on real-time traffic.

### Layer 3: The Abstraction (The Product)
*   **Managed by:** KRO.
*   **Function:** Intercepts `kind: SuperApp` and expands it into:
    *   Deployment (The Code)
    *   Service (The Networking)
    *   Ingress (The Public Access)
    *   ACK Bucket (The Storage)

---

## 5. Implementation Roadmap

### Phase 1: The Hardened Foundation (Days 1-5)
*   **Goal:** A working EKS Cluster (Lifeboat) with ArgoCD.
*   **Steps:**
    1.  **Repo Init:** Set up Monorepo structure.
    2.  **Terraform:** Create VPC, EKS (with Access Entries), and the Tainted Node Group.
    3.  **Bootstrap:** Deploy ArgoCD via Terraform (Helm Provider) onto the Lifeboat.

### Phase 2: The Engine Room (Days 6-10)
*   **Goal:** Dynamic Scaling and Public Access.
*   **Steps:**
    1.  **Karpenter:** Deploy via ArgoCD. Configure NodePool for Spot instances.
    2.  **Networking:** Deploy AWS Load Balancer Controller + ExternalDNS. Verify with Nginx.

### Phase 3: The Platform Product (Days 11-20)
*   **Goal:** Self-Service Cloud Resources.
*   **Steps:**
    1.  **Cloud Integration:** Deploy ACK S3 Controller. Verify by creating a bucket via YAML.
    2.  **The API (KRO):** Define `SuperApp` ResourceGraphDefinition. Logic: "If needsStorage: true, generate S3 Bucket."

### Phase 4: The Delivery (Final Polish)
*   **Goal:** Production Readiness.
*   **Steps:**
    1.  **ChatOps:** ArgoCD Notifications to Slack.
    2.  **Documentation:** "Timmy the Junior Dev" user guide.

