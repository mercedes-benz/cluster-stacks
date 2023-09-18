#!/usr/bin/env bash

# Copyright 2023 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o pipefail
set -x

K8S_VERSION=v1.27.2

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "${REPO_ROOT}" || exit 1

# Creates a kind cluster with the ctlptl tool https://github.com/tilt-dev/ctlptl
function ctlptl_kind-cluster() {

  local CLUSTER_NAME=$1
  local CLUSTER_VERSION=$2

  cat <<EOF | ctlptl apply -f -
apiVersion: ctlptl.dev/v1alpha1
kind: Registry
name: ${CLUSTER_NAME}-registry
port: 5000
---
apiVersion: ctlptl.dev/v1alpha1
kind: Cluster
product: kind
registry: ${CLUSTER_NAME}-registry
kindV1Alpha4Cluster:
  name: ${CLUSTER_NAME}
  nodes:
  - role: control-plane
    image: kindest/node:${CLUSTER_VERSION}
    extraMounts:
    - hostPath: /var/run/docker.sock
      containerPath: /var/run/docker.sock
  networking:
    podSubnet: "10.244.0.0/16"
    serviceSubnet: "10.96.0.0/12"
EOF
}

# Make sure the tools binaries are on the path.
export PATH="${REPO_ROOT}/hack/tools/bin:${PATH}"

echo ""
echo "Cluster initialising... Please hold on"
echo ""
ctlptl_kind-cluster scs-cluster-stacks ${K8S_VERSION}
