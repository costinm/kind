#!/usr/bin/env bash
# Copyright 2018 The Kubernetes Authors.
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

# 'go generate's kind, using tools from vendor (go-bindata)
set -o nounset
set -o errexit
set -o pipefail

set -x;

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "${REPO_ROOT}"

# enable modules and the proxy cache
export GO111MODULE="on"
GOPROXY="${GOPROXY:-https://proxy.golang.org}"
export GOPROXY

# build the generators
BINDIR="${REPO_ROOT}/_output/bin"
go build -o "${BINDIR}/defaulter-gen" k8s.io/code-generator/cmd/defaulter-gen
go build -o "${BINDIR}/deepcopy-gen" k8s.io/code-generator/cmd/deepcopy-gen
go build -o "${BINDIR}/conversion-gen" k8s.io/code-generator/cmd/conversion-gen

# turn off module mode before running the generators
# https://github.com/kubernetes/code-generator/issues/69
export GO111MODULE="off"

# run the generators
"${BINDIR}/deepcopy-gen" -i ./pkg/cluster/config/ -O zz_generated.deepcopy --go-header-file hack/boilerplate.go.txt
"${BINDIR}/defaulter-gen" -i ./pkg/cluster/config/ -O zz_generated.default --go-header-file hack/boilerplate.go.txt

"${BINDIR}/deepcopy-gen" -i ./pkg/cluster/config/v1alpha2 -O zz_generated.deepcopy --go-header-file hack/boilerplate.go.txt
"${BINDIR}/defaulter-gen" -i ./pkg/cluster/config/v1alpha2 -O zz_generated.default --go-header-file hack/boilerplate.go.txt
"${BINDIR}/conversion-gen" -i ./pkg/cluster/config/v1alpha2 -O zz_generated.conversion --go-header-file hack/boilerplate.go.txt

"${BINDIR}/deepcopy-gen" -i ./pkg/cluster/config/v1alpha3 -O zz_generated.deepcopy --go-header-file hack/boilerplate.go.txt
"${BINDIR}/defaulter-gen" -i ./pkg/cluster/config/v1alpha3 -O zz_generated.default --go-header-file hack/boilerplate.go.txt
"${BINDIR}/conversion-gen" -i ./pkg/cluster/config/v1alpha3 -O zz_generated.conversion --go-header-file hack/boilerplate.go.txt

export GO111MODULE="on"

# gofmt the tree
find . -path "./vendor" -prune -o -name "*.go" -type f -print0 | xargs -0 gofmt -s -w
