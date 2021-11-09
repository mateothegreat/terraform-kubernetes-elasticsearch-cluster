# Install elasticsearch using the operator

```hcl
provider "kubernetes" {

    config_path = "~/.kube/config"
}

module "elasticsearch-cluster" {

    source = "../"

    namespace                   = "default"
    cluster_name                = "cluster-1"
    elastic_version             = "7.13.2"
    node_count                  = 1
    role                        = "services"
    elastic_cpu_request         = "1"
    elastic_memory_request      = "4Gi"
    elastic_cpu_limit           = "1"
    elastic_memory_limit        = "4Gi"
    kibana_cpu_request          = 0.5
    kibana_memory_request       = 1
    password                    = "supersecret"
    service_type                = "LoadBalancer"
    secure_settings_secret_name = "es-s3-creds"

    #    
    # Storage settings
    #    
    disk_size_gb           = 1024
    storage_class_name     = "cluster-1"
    storage_reclaim_policy = "Delete"

}
```
