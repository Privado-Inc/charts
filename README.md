# helm
Helm chart for Privado's code analysis tool

## Using Helm Repository
1. Add Repository:
    ```
    $ helm repo add privado https://privado-inc.github.io/charts
    ```

2. Get Chart Values (`values.yaml`):
    ```
    $ helm show values privado/code-analysis > values.yaml
    ```
    These values can be set as required. 
    
3. Install 
    ```
    $ helm install privado privado/code-analysis -f values.yaml -n privado
    ```
