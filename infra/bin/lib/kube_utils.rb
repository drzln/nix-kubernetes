#!/usr/bin/env ruby
# frozen_string_literal: true
# infra/bin/lib/kube_utils.rb

require 'fileutils'

def check_minikube_installed
  return if system('command -v minikube > /dev/null')

  abort("❌ Minikube is not installed. Install it using 'brew install minikube' or download from https://minikube.sigs.k8s.io/docs/start/")
end

def install_minikube
  check_minikube_installed
  puts '✅ Minikube is installed.'
end

def start_minikube
  puts '🚀 Starting Minikube with CNI and Multus support...'
  system('minikube delete')
  system('minikube start --cni=false --driver=docker --memory=4096 --cpus=2') || abort('❌ Failed to start Minikube.')
  puts '✅ Minikube started successfully.'
end
