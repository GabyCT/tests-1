#!/usr/bin/env bats
#
# Copyright (c) 2018 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

load "${BATS_TEST_DIRNAME}/../../.ci/lib.sh"

setup() {
	busybox_image="busybox"
	export KUBECONFIG=/etc/kubernetes/admin.conf
	first_pod_name="first-test"
	second_pod_name="second-test"
	# Pull the images before launching workload.
	sudo -E crictl pull "$busybox_image"
	pod_config_dir="${BATS_TEST_DIRNAME}/untrusted_workloads"

	uts_cmd="ls -la /proc/self/ns/uts"
	ipc_cmd="ls -la /proc/self/ns/ipc"
}

@test "Check UTS and IPC namespaces" {
	issue="https://github.com/kata-containers/tests/issues/793"
	[ "${CRI_RUNTIME}" == "containerd" ] && skip "test not working with ${CRI_RUNTIME} see: ${issue}"

	# Run the first pod
	first_pod_config=$(mktemp --tmpdir pod_config.XXXXXX.yaml)
	cp "$pod_config_dir/busybox-template.yaml" "$first_pod_config"
	sed -i "s/NAME/${first_pod_name}/" "$first_pod_config"
	sudo -E kubectl create -f "$first_pod_config"
	sudo -E kubectl wait --for=condition=Ready pod "$first_pod_name"
	first_pod_uts_ns=$(sudo -E kubectl exec "$first_pod_name" -- sh -c "$uts_cmd" | grep uts | cut -d ':' -f3)
	first_pod_ipc_ns=$(sudo -E kubectl exec "$first_pod_name" -- sh -c "$ipc_cmd" | grep ipc | cut -d ':' -f3)

	# Run the second pod
	second_pod_config=$(mktemp --tmpdir pod_config.XXXXXX.yaml)
	cp "$pod_config_dir/busybox-template.yaml" "$second_pod_config"
	sed -i "s/NAME/${second_pod_name}/" "$second_pod_config"
	sudo -E kubectl create -f "$second_pod_config"
	sudo -E kubectl wait --for=condition=Ready pod "$second_pod_name"
	second_pod_uts_ns=$(sudo -E kubectl exec "$second_pod_name" -- sh -c "$uts_cmd" | grep uts | cut -d ':' -f3)
	second_pod_ipc_ns=$(sudo -E kubectl exec "$second_pod_name" -- sh -c "$ipc_cmd" | grep ipc | cut -d ':' -f3)

	# Check UTS and IPC namespaces
	[ "$first_pod_uts_ns" == "$second_pod_uts_ns" ]
	[ "$first_pod_ipc_ns" == "$second_pod_ipc_ns" ]
}

teardown() {
	sudo -E kubectl delete pod "$first_pod_name"
	sudo -E kubectl delete pod "$second_pod_name"
}
