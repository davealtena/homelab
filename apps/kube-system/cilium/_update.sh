#!/usr/bin/env bash

kustomize build . --enable-helm > base/cilium.yaml
