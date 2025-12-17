resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.7.0" # Updated to latest stable
  namespace        = "argocd"
  create_namespace = true

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
      }
      extraObjects = [
        {
          apiVersion = "argoproj.io/v1alpha1"
          kind       = "Application"
          metadata = {
            name      = "root-app"
            namespace = "argocd"
            finalizers = [
              "resources-finalizer.argocd.argoproj.io"
            ]
          }
          spec = {
            project = "default"
            source = {
              repoURL        = "https://github.com/BarryPekerman/instant-infra.git"
              targetRevision = "main"
              path           = "gitops/bootstrap"
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
      ]
    })
  ]

  depends_on = [
    aws_eks_node_group.system
  ]
}
