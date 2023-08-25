#!/bin/sh
llvmGhRepoUrl="https://github.com/llvm/llvm-project"

if [ -z "$DL_LLVM_TAG" ]; then
	echo "Error: \$DL_LDC_TAG is not set"
	exit 1
fi

if [ "$DL_LLVM_TAG" = "main" ]; then
	dlLlvmUrl="$llvmGhRepoUrl/archive/refs/heads/main.tar.gz"
else
	dlLlvmUrl="$llvmGhRepoUrl/archive/refs/tags/$DL_LLVM_TAG.tar.gz"
fi

echo "Downloading $dlLlvmUrl"
curl -fLsSo llvm.tar.gz "$dlLlvmUrl"
