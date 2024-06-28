#!/bin/bash

set -e

NAMESPACE="default"
MANIFEST="manifests/registry.yaml"

function deploy_registry() {
    kubectl apply -f $MANIFEST
    echo "Docker registry deployed in namespace $NAMESPACE"
    echo "To connect to the Docker registry, use the following address:"
    echo "localhost:5000"
}

function delete_registry() {
    kubectl delete -f $MANIFEST
    echo "Docker registry deleted from namespace $NAMESPACE"
}

function configure_registry_with_kind() {
    local cluster_name=${1:-kind}
    local reg_name='kind-registry'
    local reg_port='5001'

    # 1. Create registry container unless it already exists
    if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
        docker run \
            -d --restart=always -p "127.0.0.1:${reg_port}:5000" --network bridge --name "${reg_name}" \
            registry:2
    fi

    # 2. Add the registry config to the nodes
    REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
    for node in $(kind get nodes --name "${cluster_name}"); do
        docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
        cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"]
EOF
    done

    # 3. Connect the registry to the cluster network if not already connected
    if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
        docker network connect "kind" "${reg_name}"
    fi

    # 4. Document the local registry
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

    echo "Docker registry configured for Kind cluster '${cluster_name}' in namespace ${NAMESPACE}"
    echo "To connect to the Docker registry, use the following address:"
    echo "localhost:${reg_port}"
}

function delete_registry_with_kind() {
    local cluster_name=${1:-kind}
    local reg_name='kind-registry'

    # Stop and remove the Docker registry container
    docker stop "${reg_name}" && docker rm "${reg_name}"

    echo "Docker registry configured for Kind cluster '${cluster_name}' deleted"
}

function port_forward_registry() {
    local port=${1:-5000}
    kubectl port-forward svc/registry $port:5000 -n $NAMESPACE &
    echo "Port forwarding to Docker registry on port ${port}"
    echo "To connect to the Docker registry, use the following address:"
    echo "localhost:${port}"
}

function show_help() {
    echo "Usage: kubectl registry [command] [options]"
    echo ""
    echo "Commands:"
    echo "  create        Create the docker registry"
    echo "  delete        Delete the docker registry"
    echo "  port-forward  Port forward to the docker registry service"
    echo "  help          Show this help message"
    echo ""
    echo "Options for create and delete commands:"
    echo "  --kind        Deploy or delete in a Kind cluster with the specified cluster name (default: kind)"
    echo ""
    echo "Options for port-forward command:"
    echo "  --port        Specify the local port for port forwarding (default: 5000)"
}

COMMAND=$1
CLUSTER_NAME="kind"
USE_KIND=false
PORT=5000

shift
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --kind) USE_KIND=true; CLUSTER_NAME="${2:-kind}"; shift ;;
        --port) PORT="${2:-5000}"; shift ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

case $COMMAND in
    create)
        if $USE_KIND; then
            configure_registry_with_kind "$CLUSTER_NAME"
        else
            deploy_registry
        fi
        ;;
    delete)
        if $USE_KIND; then
            delete_registry_with_kind "$CLUSTER_NAME"
        else
            delete_registry
        fi
        ;;
    port-forward)
        port_forward_registry "$PORT"
        ;;
    help|*)
        show_help
        ;;
esac