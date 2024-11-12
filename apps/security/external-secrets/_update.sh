#!/usr/bin/env bash

kustomize build . --enable-helm > _templated/external-secrets-operator.yaml
