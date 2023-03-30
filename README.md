# Custom Clusterclass in vSphere with Tanzu 8.0

### Step 1. 
- Preferably create a new vSphere Namespace
- Login to the Supervisor cluster using `kubectl vsphere login ...`
- Make a copy of the default clusterclass `tanzukubernetescluster` and save it with a new name - e.g. `custom-tanzukubernetescluster`
```bash
$ kubectl get clusterclass tanzukubernetescluster -n demo2 -o json | jq '.metadata.name = "custom-tanzukubernetescluster"'|kubectl create -f -
$ kubectl get clusterclass -n demo2

NAME                            AGE
custom-tanzukubernetescluster   26h
tanzukubernetescluster          29h
```

- Edit the `custom-tanzukubernetescluster` clusterclass and modify chnages as needed. 
    - Perform mandatory changes to enable psp
    - Perform optional changes as needed

- Modify the `resource.yaml`. (More validations/automation pending)

```bash
$ export NAMESPACE=demo2
$ export CLUSTERNAME=workload-vsphere-tkg4
$ envsubst < resource.yaml > res-final.yaml
# Validate the the new file res-final.yaml has the env variables replaced
$ kubectl apply -f res-final.yaml
```

- Modify the `custom-classy.yaml` (More validations/automation pending)

```bash
$ envsubst < custom-classy.yaml > custom-classy-final.yaml
$ kubectl apply -f custom-classy-final.yaml
```
