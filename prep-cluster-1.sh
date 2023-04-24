#!/usr/bin/bash

###################################################
# Enter temp variables here
###################################################
export NAMESPACE=demo2
export CLUSTERNAME=workload-vsphere-tkg4

if ! command -v kubectl >/dev/null 2>&1 ; then
  echo "kubectl not installed. Exiting..."
  exit
fi

if ! command -v jq >/dev/null 2>&1 ; then
  echo "jq not installed. Exiting..."
  exit
fi


if [[ ! -f ./templates/psp.yaml ]] ; then
    echo 'Template psp.yaml does not exist. Exiting...'
    exit
fi

kubectl get deployment -n vmware-system-tkg vmware-system-tkg-controller-manager > /dev/null 2>&1
if [[ ! $? ]]; then
   echo 'KUBECONFIG context not set to Supervisor. Please login to the Supervisor cluster and/or fix the current context. Exiting...'
   exit
fi

###################################################
# Main processing starts here
###################################################
kubectl -n ${NAMESPACE} get secret ${CLUSTERNAME}-kubeconfig -o jsonpath="{.data.value}" | base64 -d > ${CLUSTERNAME}-kubeconfig
KUBECONFIG=${CLUSTERNAME}-kubeconfig kubectl apply -f psp.yaml

# Add CRB specifid data here
