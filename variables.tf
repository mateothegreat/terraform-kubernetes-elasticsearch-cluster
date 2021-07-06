variable "context" {

    type        = string
    description = "kube config context name"
    default     = null

}

variable "host" {

    type        = string
    description = "kubernetes api host"
    default     = null

}

variable "token" {

    type        = string
    description = "kubernetes api token"
    default     = null

}

variable "cluster_name" {

    type        = string
    description = "elasticsearch cluster name"

}
variable "namespace" {

    type        = string
    description = "elasticsearch cluster namespace"

}

variable "node_count" {

    type        = number
    description = "number of master node instances"

}

variable "disk_size_gb" {

    type        = number
    description = "disk size in gb"

}

variable "elastic_version" {

    type        = string
    description = "elastic version number"

}

variable "elastic_cpu_request" {

    type        = string
    description = "cpu resource limit and request"

}

variable "elastic_memory_request" {

    type        = string
    description = "memory resource limit and request"

}
variable "elastic_cpu_limit" {

    type        = string
    description = "cpu resource limit and request"

}

variable "elastic_memory_limit" {

    type        = string
    description = "memory resource limit and request"

}

variable "kibana_cpu_request" {

    type        = number
    description = "cpu resource limit and request"

}

variable "kibana_memory_request" {

    type        = number
    description = "memory resource limit and request"

}

variable "password" {

    type        = string
    description = "elasticsearch password"

}

variable "service_type" {

    type        = string
    description = "kubernetes service type"
    default     = "ClusterIP"

}

variable "secure_settings_secret_name" {

    type        = string
    description = "k8 secret name olding keystore secret data to be added to the cluster"
    default     = null

}

variable "role" {

    type        = string
    description = "nole_selector value for role=<something>"
    default     = null

}

variable "storage_class_name" {

    type        = string
    description = "name of the storage class we will create to support dynamic resizing of the underlying volumes"
    default     = "gp2-expandable"

}

variable "storage_reclaim_policy" {

    type        = string
    description = "policy for the volumes when deleted (this should be either Retain or Delete)"
    default     = "Delete"

}

variable "cluster_ca_certificate" {

    type = string
    description = "cluster ca"
    default = null

}

variable "insecure" {

    type = bool
    description = "skip certificate validation"
    default = false

}