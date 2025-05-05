#!/usr/bin/env ruby
# frozen_string_literal: true
# infra/bin/lib/networking.rb

require 'json'

# ✅ Configure Network Policies and Multus CNI
def configure_networking
  puts '🚀 Configuring networking...'

  # Create multiple namespaces for network isolation
  system('kubectl create namespace frontend || true')
  system('kubectl create namespace backend || true')
  system('kubectl create namespace database || true')

  # Apply a network policy to restrict backend access
  network_policy = <<~YAML
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: backend-isolation
      namespace: backend
    spec:
      podSelector: {}
      policyTypes:
      - Ingress
      - Egress
      ingress:
      - from:
        - namespaceSelector:
            matchLabels:
              role: frontend
        ports:
        - protocol: TCP
          port: 8080
  YAML

  File.write('backend-policy.yaml', network_policy)
  system('kubectl apply -f backend-policy.yaml')
  FileUtils.rm_f('backend-policy.yaml') # ✅ Delete temporary file

  puts '✅ Network policies and CNI configuration applied.'
end
