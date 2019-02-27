#!/usr/bin/env bats
#
# Copyright (c) 2018 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

load "${BATS_TEST_DIRNAME}/../../.ci/lib.sh"

setup() {
	export KUBECONFIG=/etc/kubernetes/admin.conf
	if sudo -E kubectl get runtimeclass | grep kata; then
		pod_config_dir="${BATS_TEST_DIRNAME}/runtimeclass_workloads"
	else
		pod_config_dir="${BATS_TEST_DIRNAME}/untrusted_workloads"
	fi
}

@test "Credentials using secrets" {
	secret_name="test-secret"
	pod_name="secret-test-pod"
	second_pod_name="secret-envars-test-pod"

	# Create the secret
	sudo -E kubectl create -f "${pod_config_dir}/inject_secret.yaml"

	# View information about the secret
	sudo -E kubectl get secret "${secret_name}" -o yaml | grep "type: Opaque"

	# Create a pod that has access to the secret through a volume
	sudo -E kubectl create -f "${pod_config_dir}/pod-secret.yaml"

	# Check pod creation
	sudo -E kubectl wait --for=condition=Ready pod "$pod_name"

	# List the files
	cmd="ls /tmp/secret-volume"
	sudo -E kubectl exec $pod_name -- sh -c "$cmd" | grep -w "password"
	sudo -E kubectl exec $pod_name -- sh -c "$cmd" | grep -w "username"

	# Create a pod that has access to the secret data through environment variables
	sudo -E kubectl create -f "${pod_config_dir}/pod-secret-env.yaml"

	# Check pod creation
	sudo -E kubectl wait --for=condition=Ready pod "$second_pod_name"

	# Display environment variables
	second_cmd="printenv"
	sudo -E kubectl exec $second_pod_name -- sh -c "$second_cmd" | grep -w "SECRET_USERNAME"
	sudo -E kubectl exec $second_pod_name -- sh -c "$second_cmd" | grep -w "SECRET_PASSWORD"
}

teardown() {
	sudo -E kubectl delete pod "$pod_name" "$second_pod_name"
	sudo -E kubectl delete secret "$secret_name"
}
