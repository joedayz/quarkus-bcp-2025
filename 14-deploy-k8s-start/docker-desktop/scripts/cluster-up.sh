#!/bin/sh
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found. Install Docker Desktop first." >&2
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found. Install kubectl first." >&2
  exit 1
fi

# Verificar que Docker Desktop esté ejecutándose
if ! docker info >/dev/null 2>&1; then
  echo "Docker Desktop no está ejecutándose. Por favor, inicia Docker Desktop." >&2
  exit 1
fi

# Verificar que Kubernetes esté habilitado en Docker Desktop
if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Kubernetes no está disponible en Docker Desktop." >&2
  echo "Por favor, habilita Kubernetes en Docker Desktop:" >&2
  echo "  Settings > Kubernetes > Enable Kubernetes" >&2
  exit 1
fi

echo "Docker Desktop Kubernetes está disponible."
kubectl cluster-info
echo ""
echo "Contexto actual: $(kubectl config current-context)"
