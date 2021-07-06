# Install elasticsearch using the operator

```hcl
variable "cluster_name" {}
variable "aws_profile" {}
variable "aws_region" {}

#terraform {
#
#    backend "s3" {}
#
#}

provider "aws" {

    profile = var.aws_profile
    region  = var.aws_region

}

data "aws_eks_cluster" "cluster" {

    name = var.cluster_name

}

data "aws_eks_cluster_auth" "cluster" {

    name = var.cluster_name

}

module "elasticsearch-cluster" {

    source  = ""
    version = ""
    
    host                        = data.aws_eks_cluster.cluster.endpoint
    token                       = data.aws_eks_cluster_auth.cluster.token
    cluster_name                = "cluster-1"
    namespace                   = "default"
    elastic_version             = "7.9.2"
    node_count                  = 3
    role                        = "infra"
    elastic_cpu_request         = "2"
    elastic_memory_request      = "30Gi"
    elastic_cpu_limit           = "2"
    elastic_memory_limit        = "32Gi"
    kibana_cpu_request          = 0.5
    kibana_memory_request       = 2
    password                    = "Agby5kma0130"
    service_type                = "LoadBalancer"
    secure_settings_secret_name = "es-s3-creds"
    
    #    
    # Storage settings
    #    
    disk_size_gb                = 1024
    storage_class_name          = "cluster-1"
    storage_reclaim_policy      = "Delete"
    
}
```
