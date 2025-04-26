#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

# ✅ Check if Minikube is installed
def check_minikube_installed
  return if system('command -v minikube > /dev/null')

  abort("❌ Minikube is not installed. Install it using 'brew install minikube' or download from https://minikube.sigs.k8s.io/docs/start/")
end

# ✅ Install Minikube (if missing)
def install_minikube
  check_minikube_installed
  puts '✅ Minikube is installed.'
end

# ✅ Start Minikube with the correct options
def start_minikube
  puts '🚀 Starting Minikube with CNI and Multus support...'
  system('minikube delete') # Ensure a fresh start
  # system('minikube start --cni=multus --network-plugin=cni --driver=docker --memory=4096 --cpus=2') || abort('❌ Failed to start Minikube.')
  system('minikube start --cni=false --driver=docker --memory=4096 --cpus=2') || abort('❌ Failed to start Minikube.')
  puts '✅ Minikube started successfully.'
end
