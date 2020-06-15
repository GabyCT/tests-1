#!/bin/bash
#
# Copyright (c) 2017-2020 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

# This script will execute the Kata Containers Test Suite.

set -e

cidir=$(dirname "$0")
source "${cidir}/lib.sh"

export RUNTIME="containerd-shim-kata-v2"

export CI_JOB="${CI_JOB:-default}"

case "${CI_JOB}" in
	"CRI_CONTAINERD_K8S")
		echo "INFO: Containerd checks"
		sudo -E PATH="$PATH" bash -c "make cri-containerd"
		sudo -E PATH="$PATH" CRI_RUNTIME="containerd" bash -c "make kubernetes"
		;;
	"CRIO_K8S")
		sudo -E PATH="$PATH" bash -c "make crio"
		;;
esac
