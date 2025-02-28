#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

PLATFORM="$(uname -s)-$(uname -m)"
ROOT_DIR=$(git rev-parse --show-toplevel)
YQ="$ROOT_DIR/bin/$PLATFORM/yq"

# Apply patch-bundle-csv-scc.yaml on CSV file
# (cannot be done using Kustomize as the final CSV is generated by operator-sdk binary)
$YQ m -i -a "$ROOT_DIR/bundle/manifests/datadog-operator.clusterserviceversion.yaml" "$ROOT_DIR/hack/patch-bundle-csv-scc.yaml"

# Add annotation required for upstream publication
IMAGE=$($YQ r bundle/manifests/datadog-operator.clusterserviceversion.yaml 'spec.install.spec.deployments[0].spec.template.spec.containers[0].image')
$YQ w -i bundle/manifests/datadog-operator.clusterserviceversion.yaml 'metadata.annotations.containerImage' "$IMAGE"

# Add skipRange annotation to allow direct upgrades
VERSION=$($YQ r bundle/manifests/datadog-operator.clusterserviceversion.yaml 'spec.version')
$YQ w -i bundle/manifests/datadog-operator.clusterserviceversion.yaml 'metadata.annotations."olm.skipRange"' "<$VERSION"

# Delete replaces
$YQ d -i bundle/manifests/datadog-operator.clusterserviceversion.yaml 'spec.replaces'

# Add OpenShift version annotation (adding in main bundle as it's used for OpenShift Community)
$YQ w -i bundle/metadata/annotations.yaml 'annotations."com.redhat.openshift.versions"' "v4.6"
