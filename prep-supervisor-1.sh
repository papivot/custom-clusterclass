#!/usr/bin/bash

###################################################
# Enter temp variables here
###################################################
export NAMESPACE=demo2
export CLUSTERNAME=workload-vsphere-tkg4

if ! command -v openssl >/dev/null 2>&1 ; then
  echo "openssl not installed. Exiting..."
  exit
fi

if ! command -v kubectl >/dev/null 2>&1 ; then
  echo "kubectl not installed. Exiting..."
  exit
fi

if [[ ! -f ./templates/temp-pre-workloadcluster-resources.yaml ]] ; then
    echo 'Template temp-pre-workloadcluster-resources.yaml does not exist. Exiting...'
    exit
fi

if [[ ! -f ./templates/temp-cluster-encryption-config.yaml ]] ; then
    echo 'Template temp-cluster-encryption-config.yaml does not exist. Exiting...'
    exit
fi

kubectl get deployment -n vmware-system-tkg vmware-system-tkg-controller-manager > /dev/null 2>&1
if [[ ! $? ]]; then
   echo 'KUBECONFIG context not set to Supervisor. Please login to the Supervisor cluster and/or fix the current context. Exiting...'
   exit
fi

echo "Preparing Supervisor objects objects required for the deployment of ${CLUSTERNAME} ..."
###################################################
# Main processing starts here
###################################################
PASSWD=$(openssl rand -base64 32)
ENCRYP=$(openssl rand -base64 32)
HPASSWD=$(openssl passwd -6 ${PASSWD})
openssl genrsa -out rsa.priv 4096
openssl rsa -in rsa.priv -out rsa.pub -pubout -outform PEM

export B64PASSWD=$(echo ${PASSWD}|base64 -w0)
export B64ENCRYP=$(echo ${ENCRYP}|base64 -w0)
export B64HPASSWD=$(echo ${HPASSWD}|base64 -w0)
export B64SSHPRIVKEY=$(base64 -w0 ./rsa.priv)
export B64SSHPUBKEY=$(base64 -w0 ./rsa.pub)
export ENCRYP

envsubst < ./templates/temp-pre-workloadcluster-resources.yaml > pre-workloadcluster-resources-${CLUSTERNAME}.yaml

echo "Creating Supervisor objects objects required for the deployment of ${CLUSTERNAME} ..."
kubectl apply -n ${NAMESPACE} -f ./pre-workloadcluster-resources-${CLUSTERNAME}.yaml

echo
echo "Use the folllwing B64 encoded string for the ${CLUSTENAME} cluster.spec.topology.variables.clusterEncryptionConfigYaml.values... "
echo
envsubst < ./templates/temp-cluster-encryption-config.yaml > cluster-encryption-config-${CLUSTERNAME}.yaml
base64 -w0 ./cluster-encryption-config-${CLUSTERNAME}.yaml;echo

rm ./rsa.priv
rm ./rsa.pub
rm ./cluster-encryption-config-${CLUSTERNAME}.yaml