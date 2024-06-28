#!/bin/bash

set -e

NAMESPACE="default"
MANIFEST="manifests/registry.yaml"

function deploy_registry() {
    kubectl apply -f $MANIFEST
    echo "Docker registry deployed in namespace $NAMESPACE"
}

function delete_registry() {
    kubectl delete -f $MANIFEST
    echo "Docker registry deleted from namespace $NAMESPACE"
}

function show_help() {
    echo "Usage: kubectl registry [command]"
    echo ""
    echo "Commands:"
    echo "  create   Create the docker registry"
    echo "  delete   Delete the docker registry"
    echo "  help     Show this help message"
}

COMMAND=$1

case $COMMAND in
    create)
        deploy_registry
        ;;
    delete)
        delete_registry
        ;;
    help|*)
        show_help
        ;;
esac