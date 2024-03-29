#resource "kubernetes_manifest" "credentials" {
#
#    manifest = {
#
#        "apiVersion" = "v1"
#        "kind"       = "Secret"
#
#        "metadata" = {
#
#            "namespace" = var.namespace
#            "name"      = "${ var.cluster_name }-es-elastic-user"
#
#        }
#
#        "data" = {
#
#            "elastic" = base64encode(var.password)
#
#        }
#
#    }
#
#}

resource "kubernetes_storage_class" "storage" {

    metadata {

        name = var.storage_class_name

    }

    storage_provisioner    = "kubernetes.io/aws-ebs"
    reclaim_policy         = var.storage_reclaim_policy
    allow_volume_expansion = true
    volume_binding_mode    = "WaitForFirstConsumer"

    parameters = {

        type = "gp2"

    }


}

resource "kubernetes_manifest" "elasticsearch" {

    field_manager {

        force_conflicts = true

    }

    manifest = {

        "apiVersion" = "elasticsearch.k8s.elastic.co/v1"
        "kind"       = "Elasticsearch"

        "metadata" = {

            namespace = var.namespace
            name      = var.cluster_name

        }

        "spec" = {

            "version" = var.elastic_version

            "http" = {

                "service" = {

                    "metadata" = {

                        "annotations" = {

                            "service.beta.kubernetes.io/aws-load-balancer-type"     = "nlb"
                            "service.beta.kubernetes.io/aws-load-balancer-internal" = "0.0.0.0/0"

                        }

                    }

                    "spec" = {

                        "type" = var.service_type

                    }

                }

                "tls" = {

                    "selfSignedCertificate" = {

                        "disabled" = true

                    }

                }

            }

            "nodeSets" = [

                {

                    config = {

                        "node.data"        = true
                        "node.ingest"      = true
                        "node.master"      = true
                        "xpack.ml.enabled" = true

                    }

                    count = var.node_count
                    name  = "master"

                    podTemplate = {

                        "spec" = {

                            nodeSelector = {

                                role = var.role

                            }

                            affinity = {

                                nodeAffinity = {

                                    requiredDuringSchedulingIgnoredDuringExecution = {

                                        nodeSelectorTerms = [

                                            {

                                                matchExpressions = [

                                                    {

                                                        key      = "role"
                                                        operator = "In"
                                                        values   = [ var.role ]

                                                    }

                                                ]

                                            }

                                        ]

                                    }

                                }

                            }

                            "containers" = [

                                {

                                    name = "elasticsearch"

                                    env = [

                                        {

                                            name  = "ES_JAVA_OPTS"
                                            value = "-Xms${ replace(var.elastic_memory_request, "Gi", "") }g -Xmx${ replace(var.elastic_memory_request, "Gi", "") }g"

                                        }

                                    ]

                                    resources = {

                                        "limits" = {

                                            "cpu"    = var.elastic_cpu_limit
                                            "memory" = var.elastic_memory_limit

                                        }

                                        "requests" = {

                                            "cpu"    = var.elastic_cpu_limit
                                            "memory" = var.elastic_memory_limit

                                        }

                                    }

                                }

                            ]

                            "initContainers" = [

                                {

                                    name = "sysctl"

                                    command = [

                                        "sh",
                                        "-c",
                                        "sysctl -w vm.max_map_count=262144",

                                    ]

                                    securityContext = {

                                        "privileged" = true

                                    }

                                },
                                {

                                    name = "install-plugins"

                                    command = [

                                        "sh",
                                        "-c",
                                        "bin/elasticsearch-plugin install --batch repository-s3",

                                    ]

                                    resources = {

                                        "limits" = {

                                            "cpu"    = "100m"
                                            "memory" = "1Gi"

                                        }

                                        "requests" = {

                                            "cpu"    = "100m"
                                            "memory" = "1Gi"

                                        }

                                    }

                                }

                            ]

                        }

                    }

                    volumeClaimTemplates = [

                        {

                            metadata = {

                                "name" = "elasticsearch-data"

                            }

                            spec = {

                                "accessModes" = [

                                    "ReadWriteOnce"

                                ]

                                "resources" = {

                                    "requests" = {

                                        "storage" = "${ var.disk_size_gb }Gi"

                                    }

                                }

                                "storageClassName" = var.storage_class_name

                            }

                        },

                    ]

                }

            ]

            secureSettings = [

                {

                    secretName = var.secure_settings_secret_name

                }

            ]

        }

    }

}

resource "kubernetes_manifest" "kibana" {

    depends_on = [

        kubernetes_storage_class.storage

    ]

    computed_fields = [ "object", "metadata", "spec" ]

    field_manager {

        force_conflicts = true
    }

    manifest = {

        "apiVersion" = "kibana.k8s.elastic.co/v1"
        "kind"       = "Kibana"

        "metadata" = {

            namespace         = var.namespace
            "name"            = var.cluster_name
            creationTimestamp = null

        }

        "spec" = {

            "version" = var.elastic_version
            "count"   = 1

            "elasticsearchRef" = {

                "namespace" = var.namespace
                "name"      = var.cluster_name

            }

            "http" = {

                "service" = {

                    "metadata" = {

                        "annotations" = {

                            "service.beta.kubernetes.io/aws-load-balancer-type"     = "nlb"
                            "service.beta.kubernetes.io/aws-load-balancer-internal" = "0.0.0.0/0"

                        }

                    }

                    "spec" = {

                        "type" = var.service_type

                    }

                }

                "tls" = {

                    "selfSignedCertificate" = {

                        "disabled" = true

                    }

                }

            }

            podTemplate = {

                metadata = {

                    creationTimestamp = null

                }

                "spec" = {

                    affinity = {

                        nodeAffinity = {

                            requiredDuringSchedulingIgnoredDuringExecution = {

                                nodeSelectorTerms = [

                                    {

                                        matchExpressions = [

                                            {

                                                key      = "role"
                                                operator = "In"
                                                values   = [ var.role ]

                                            }

                                        ]

                                    }

                                ]

                            }

                        }

                    }

                    "containers" = [

                        {

                            name = "kibana"

                            resources = {

                                "limits" = {

                                    "cpu"    = var.kibana_cpu_request
                                    "memory" = var.kibana_memory_request

                                }

                                "requests" = {

                                    "cpu"    = var.kibana_cpu_request
                                    "memory" = var.kibana_memory_request

                                }

                            }

                        }

                    ]

                }

            }

        }

    }

}
