# Charts


## Checklist

In the [values.yaml](./values.yaml) file, verify the following attribute:

1. The base variables, especially `isProduction`, `host` and `protocol`.
2. Ingress values: `ingressClassName` and/or required `annotations`.
3. Images: Validate `image.name` and `image.tag` values for `andromeda` and `bishamonten`.
4. Resources: All `cpu` and `memory` values.
5. Storage: All `storage` values to set storage size. As well as the `storageClass` to configure which storage will be used.
6. Update values in `enterpriseConf`.
