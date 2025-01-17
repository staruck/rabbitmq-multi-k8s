#!/bin/bash
mkdir ./certificates
mkdir ./certificates/$NAMESPACE_RABBIT-$REGION01/
mkdir ./certificates/$NAMESPACE_RABBIT-$REGION02/
mkdir ./certificates/authority/
mkdir ./kubernetes
mkdir ./kubernetes/$K8S01/
mkdir ./kubernetes/$K8S01/$NAMESPACE_RABBIT/
mkdir ./kubernetes/$K8S02/
mkdir ./kubernetes/$K8S02/$NAMESPACE_RABBIT/