#!/usr/bin/env bash

kustomize build . --enable-helm > base/onepassword-connect.yaml
