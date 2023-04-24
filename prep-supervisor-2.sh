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

if [[ ! -f ./templates/temp-post-workloadcluster-resources.yaml ]] ; then
    echo 'Template temp-post-workloadcluster-resources.yaml does not exist. Exiting...'
    exit
fi

if [[ ! -f ./templates/temp-secret.txt]] ; then
    echo 'Template temp-secret.txt does not exist. Exiting...'
    exit
fi

kubectl get deployment -n vmware-system-tkg vmware-system-tkg-controller-manager > /dev/null 2>&1
if [[ ! $? ]]; then
   echo 'KUBECONFIG context not set to Supervisor. Please login to the Supervisor cluster and/or fix the current context. Exiting...'
   exit
fi

echo "Preparing Supervisor objects required post deployment of ${CLUSTERNAME} ..."

###################################################
# Main processing starts here
###################################################

CUID=$(kubectl get -n ${NAMESPACE} cluster ${CLUSTERNAME} -o json|jq -r '.metadata.uid')
VCINFO=$(kubectl -n vmware-system-capw get cm vc-public-keys -o json|jq -r '.data."vsphere.local.json"'|jq -rc --arg cluid "$CUID" '.client_id |= .+ ":" + $cluid')
CERT=$(kubectl get -n ${NAMESPACE} secret ${CLUSTERNAME}-auth-svc-cert -o json|jq -r '.data."tls.crt"'|base64 -d )
KEY=$(kubectl get -n ${NAMESPACE} secret ${CLUSTERNAME}-auth-svc-cert -o json|jq -r '.data."tls.key"')

export VCINFO
export CERT
export KEY

envsubst < ./templates/temp-secret.txt > temp-secret.txt
sed -i '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/ s/^/    /' temp-secret.txt
export B64AUTH=$(base64 -w0 temp-secret.txt)

envsubst < ./templates/temp-post-workloadcluster-resources.yaml > post-workloadcluster-resources-${CLUSTERNAME}.yaml
echo "Creating Supervisor objects required post deployment of cluster ${CLUSTERNAME} ..."
kubectl apply -n ${NAMESPACE} -f ./post-workloadcluster-resources-${CLUSTERNAME}.yaml

sleep 5
kubectl get ClusterBootstrap -n ${NAMESPACE} ${CLUSTERNAME} -o json |jq 'del(.metadata, .status)' > ./${CLUSTERNAME}-cb.json

if ! grep -q  ${CLUSTERNAME}-guest-cluster-auth-service-data-values ./${CLUSTERNAME}-cb.json ; then
	jq --arg clname "$CLUSTERNAME" '.spec.additionalPackages |= map(select(.refName == "guest-cluster-auth-service.tanzu.vmware.com.1.0.0+tkg.2-zshippable") |= . + {"valuesFrom": {"secretRef": ($clname+"-guest-cluster-auth-service-data-values")}})' ./${CLUSTERNAME}-cb.json > ./${CLUSTERNAME}-cb-patch.json
	kubectl patch ClusterBootstrap -n ${NAMESPACE} ${CLUSTERNAME} --patch-file ./${CLUSTERNAME}-cb-patch.json --type merge
fi

rm -f ./temp-secret.txt
rm -f ./${CLUSTERNAME}-cb.json
rm -f ./${CLUSTERNAME}-cb-patch.json