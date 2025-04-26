#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

# ✅ Install ArgoCD
def install_argo_cd
  puts '🚀 Installing ArgoCD...'
  system('kubectl create namespace argocd || true')
  system('kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml') || abort('❌ Failed to install ArgoCD.')
  puts '✅ ArgoCD installed.'
end

# ✅ Expose ArgoCD API
def expose_argo_cd
  puts '🚀 Exposing ArgoCD API...'
  system('kubectl port-forward svc/argocd-server -n argocd 8080:443 &') # Runs in the background
  sleep 5 # Give it time to start
  puts '✅ ArgoCD available at https://localhost:8080'
end
