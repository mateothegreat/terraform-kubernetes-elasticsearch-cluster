variable "cluster_name" {

    type = string
    description = "elasticsearch cluster name"

}
variable "namespace" {

    type = string
    description = "elasticsearch cluster namespace"

}

variable "node_count" {

    type = number
    description = "number of master node instances"

}

variable "disk_size_gb" {

    type = number
    description = "disk size in gb"

}

variable "elastic_version" {

    type = string
    description = "elastic version number"

}

variable "elastic_cpu_request" {

    type = number
    description = "cpu resource limit and request"

}

variable "elastic_memory_request" {

    type = number
    description = "memory resource limit and request"

}

variable "kibana_cpu_request" {

    type = number
    description = "cpu resource limit and request"

}

variable "kibana_memory_request" {

    type = number
    description = "memory resource limit and request"

}

variable "password" {

    type = string
    description = "elasticsearch password"

}

variable "service_type" {

    type = string
    description = "kubernetes service type"
    default = "ClusterIP"

}
