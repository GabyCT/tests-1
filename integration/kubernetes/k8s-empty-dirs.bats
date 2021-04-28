#!/usr/bin/env bats
#
# Copyright (c) 2019 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

load "${BATS_TEST_DIRNAME}/../../.ci/lib.sh"
load "${BATS_TEST_DIRNAME}/../../lib/common.bash"
source /etc/os-release || source /usr/lib/os-release
issue="https://github.com/kata-containers/tests/issues/3464"

assert_equal() {
	[ "${ID}" == "centos" ] && skip "test not working see ${issue}"
	local expected=$1
	local actual=$2
	if [[ "$expected" != "$actual" ]]; then
	echo "expected: $expected, got: $actual"
	return 1
	fi
}

setup() {
	[ "${ID}" == "centos" ] && skip "test not working see ${issue}"
	export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
	pod_name="sharevol-kata"
	get_pod_config_dir
	pod_logs_file=""
	wait_time=20
	sleep_time=2
}

@test "Empty dir volumes" {
	[ "${ID}" == "centos" ] && skip "test not working see ${issue}"
	# Create the pod
	kubectl create -f "${pod_config_dir}/pod-empty-dir.yaml"

	# Check pod creation
	kubectl wait --for=condition=Ready --timeout=$timeout pod "$pod_name"

	# Check volume mounts
	cmd="mount | grep cache"
	kubectl exec $pod_name -- sh -c "$cmd" | grep "/tmp/cache type tmpfs"
}

@test "Empty dir volume when FSGroup is specified with non-root container" {
	[ "${ID}" == "centos" ] && skip "test not working see ${issue}"
	# This is a reproducer of k8s e2e "[sig-storage] EmptyDir volumes when FSGroup is specified [LinuxOnly] [NodeFeature:FSGroup] new files should be created with FSGroup ownership when container is non-root" test
	pod_file="${pod_config_dir}/pod-empty-dir-fsgroup.yaml"
	agnhost_name=$(get_test_version "container_images.agnhost.name")
	agnhost_version=$(get_test_version "container_images.agnhost.version")
	image="${agnhost_name}:${agnhost_version}"

	# Try to avoid timeout by prefetching the image.
	crictl_pull "$image"
	sed -e "s#\${agnhost_image}#${image}#" "$pod_file" |\
		kubectl create -f -
	cmd="kubectl get pods ${pod_name} | grep Completed"
	waitForProcess "${wait_time}" "${sleep_time}" "${cmd}"

	pod_logs_file="$(mktemp)"
	for container in mounttest-container mounttest-container-2; do
		kubectl logs "$pod_name" "$container" > "$pod_logs_file"
		# Check owner UID of file
		uid=$(cat $pod_logs_file | grep 'owner UID of' | sed 's/.*:\s//')
		assert_equal "1001" "$uid"
		# Check owner GID of file
		gid=$(cat $pod_logs_file | grep 'owner GID of' | sed 's/.*:\s//')
		assert_equal "123" "$gid"
	done
}

teardown() {
	[ "${ID}" == "centos" ] && skip "test not working see ${issue}"
	# Debugging information
	kubectl describe "pod/$pod_name"

	kubectl delete pod "$pod_name"

	[ ! -f "$pod_logs_file" ] || rm -f "$pod_logs_file"
}
