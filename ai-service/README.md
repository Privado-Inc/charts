# Charts

The Helm charts for deploying the AI Service. There are two charts for deploying the Ai Service and ChromaDB containers.
The ChromaDB chart is a dependency for the Ai Service chart.

## Prerequisites

1. In the kubernetes cluster, the following resources should be available:
    - `g5.xlarge` instance type for the Ai Service container. Or change the instance type in the values.yaml file.
    - The Ai Service container/pod should be able to connect the Andromeda service.
    - The Nvidia GPU driver should be installed in the node.
    - The nvidia-device-plugin should be installed in the cluster.
        - `kubectl get nodes "-o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu"` to confirm
          the GPU availability.
2. In the [values.yaml](./values.yaml) file, verify the following attributes:
    - Update the following environment variables for the Ai Service container as needed
        - AI_SERVICE_ANDROMEDA_HOST: "http://andromeda-service.privado.svc.cluster.local:6001"
        - CHROMA_HOST: "ai-service-chroma-chromadb.privado.svc.cluster.local"
            - Without any port, the default port (8000) is used.
            - Without the 'http://' prefix.
    - NodeSelector configuration
        - `node.kubernetes.io/instance-type: g5.xlarge` update the instance type as needed.
            - A GPU core with 24GB+ vRAM is a requirement to deploy the Ai Service container.
    - Persistent Volume configuration
        - Update the storage class name as needed.
        - Update the storage size as needed.
    - Update the AWS credentials to provide the access key and secret key.
3. **Updating values.yaml with init.sh.** Instead of manually editing the values.yaml file, the init.sh script can be
   used to set the necessary values.
    - To run the script: `bash init.sh`
    - The script will prompt you for various values. If you do not provide a new value, the default value will be used. 
      The script will update the values.yaml file with the provided values, ensuring that all necessary configurations 
      are set correctly. It is also keep a backup of the original values.yaml file. If you want to revert to the 
      original values.yaml file (or run this script again), you can use the backup file.
4. **Adding custom annotations and labels.** If you want to add custom annotations and labels to the Ai Service pod, you
   can do so by updating the values.yaml file. The annotations and labels are added to the pod spec in the deployment
   template. You can add the annotations and labels under the `annotations` and `labels` sections in the values.yaml file.
   The annotations and labels should be in key-value format. For example:
    ```yaml
    annotations:
      key1: value1
      key2: value2
    labels:
      key1: value1
      key2: value2
    ```
5. Install ChromaDb helm chart before installing the Ai Service chart using the following commands:

```bash
   helm repo add chroma https://amikos-tech.github.io/chromadb-chart/
   helm repo update
   helm search repo chroma/
   kubectl create namespace privado
   helm install ai-service-chroma chroma/chromadb -n privado --set chromadb.allowReset="true" --set chromadb.auth.enabled="false" --set chromadb.serverHost="chromadb"
```

# Deploying the AI Service

Following steps will deploy ai-service chart:

1. `kubectl config current-context` to verify the kubectl context.
2. `helm package .` to package the Ai Service chart.
3. `helm install ai-service ai-service-0.1.0.tgz -n privado` to install the Ai Service chart.

# Post Installation Steps

Following steps will verify the installation of ai-service chart:

1. `kubectl get pods` to verify the Ai Service pods are running.
2. `kubclt logs -f <pod-name>` to view the container logs of the Ai Service pod.
3. `kubclt exec -it <pod-name> -- /bin/bash` to access the Ai Service container shell.
    - `tais` to view the ai-service logs. Following like should be visible:
        - `GET / => generated X bytes in Y msecs (HTTP/1.1 200) 8 headers in Z bytes`

Following steps will verify successful integration with Privado backend:

1. Login to the Privado dashboard.
2. Navigate to the "Contract Scanning" menu
3. Upload a DPA (Data Protection Agreement) pdf. Any public DPA is fine.
4. Verify that the DPA is scanned and the results are displayed in the dashboard.

# Uninstalling the AI Service

Following steps will uninstall ai-service chart:

1. `helm uninstall ai-service` to uninstall the Ai Service chart.
2. `helm uninstall ai-service-chroma` to uninstall the ChromaDB chart.