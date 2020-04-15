#!/bin/bash
#
# Copyright (c) 2017-2018 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

set -o errexit
set -o nounset
set -o pipefail

cidir=$(dirname "$0")
tag="${1:-""}"
source /etc/os-release || source /usr/lib/os-release
source "${cidir}/lib.sh"
KATA_HYPERVISOR="${KATA_HYPERVISOR:-qemu}"
experimental_qemu="${experimental_qemu:-false}"

echo "Install kata-containers image"
"${cidir}/install_kata_image.sh"

echo "Install Kata Containers Kernel"
"${cidir}/install_kata_kernel.sh"

if [ "$KATA_HYPERVISOR" == "firecracker" ]; then
	echo "Install Firecracker"
	"${cidir}/install_firecracker.sh"
else
	if [ "$experimental_qemu" == "true" ]; then
		echo "Install experimental Qemu"
		"${cidir}/install_qemu_experimental.sh"
	else
		echo "Install Qemu"
		"${cidir}/install_qemu.sh"
	fi
fi

echo "Install shim"
"${cidir}/install_shim.sh" "${tag}"

echo "Install proxy"
"${cidir}/install_proxy.sh" "${tag}"

echo "Install runtime"
"${cidir}/install_runtime.sh" "${tag}"
