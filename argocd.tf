resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.51.6" # Pinning version for stability
  namespace        = "argocd"
  create_namespace = true

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]

  depends_on = [
    aws_eks_node_group.system
  ]
}

# Bootstrap the Root App
resource "helm_release" "argocd_apps" {
  name             = "argocd-apps"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-apps"
  version          = "1.6.2"
  namespace        = "argocd"

  values = [
    yamlencode({
      applications = {
        root-app = {
          namespace = "argocd"
          project   = "default"
          source = {
            repoURL        = "https://github.com/BarryPekerman/instant-infra.git"
            targetRevision = "main"
            path           = "gitops/apps"
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "argocd"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
          }
        }
      }
    })
  ]

  depends_on = [
    helm_release.argocd
  ]
}
