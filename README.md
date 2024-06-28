# kubectl-registry

A `kubectl` plugin to deploy and delete a Docker registry in a local Kubernetes cluster. It also supports configuration for an existing Kind cluster.

## Features

- Deploy a Docker registry using a Kubernetes manifest.
- Configure a Docker registry for an existing Kind cluster.
- Delete the Docker registry.

## Prerequisites

- Kubernetes cluster (local or remote).
- `kubectl` installed.
- `krew` installed.
- Kind cluster (optional, if using the `--kind` option).

## Installation


# Install kubectl-registry Plugin
Clone this repository and navigate to the plugin directory:

```sh
krew install --manifest-url=https://raw.githubusercontent.com/maxyloon/registry-plugin/main/plugin.yaml
```

# Usage
```sh
Usage: kubectl registry [command] [options]

Commands:
  create        Create the docker registry
  delete        Delete the docker registry
  port-forward  Port forward to the docker registry service
  help          Show this help message

Options for create and delete commands:
  --kind        Deploy or delete in a Kind cluster with the specified cluster name (default: kind)

Options for port-forward command:
  --port        Specify the local port for port forwarding (default: 5000)
```

# Contributing
Contributions are welcome! Please open an issue or submit a pull request.

# License
This project is licensed under the MIT License - see the LICENSE file for details.
