#!/usr/bin/env bash

kustomize build . --enable-helm > base/external-secrets-operator.yaml
