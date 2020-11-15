provider "kubernetes-alpha" {

    alias                  = "k8"
    config_path            = "~/.kube/config"
    config_context_cluster = var.context
    host                   = var.host
    token                  = var.token
    insecure               = true
    server_side_planning   = false

}

resource "kubernetes_manifest" "credentials" {

    provider = kubernetes-alpha.k8

    manifest = {

        "apiVersion" = "v1"
        "kind"       = "Secret"

        "metadata" = {

            "namespace" = var.namespace
            "name"      = "${ var.cluster_name }-es-elastic-user"

        }

        "data" = {

            "elastic" = base64encode(var.password)

        }

    }

}

resource "kubernetes_manifest" "elasticsearch" {

    provider = kubernetes-alpha.k8

    manifest = {

        "apiVersion" = "elasticsearch.k8s.elastic.co/v1"
        "kind"       = "Elasticsearch"

        "metadata" = {

            namespace = var.namespace
            name      = var.cluster_name

        }

        "spec" = {

            "version" = var.elastic_version

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

                            "containers" = [

                                {

                                    name = "elasticsearch"

                                    env = [

                                        {

                                            name  = "ES_JAVA_OPTS"
                                            value = "-Xms${ var.elastic_memory_request - 1 }g -Xmx${ var.elastic_memory_request - 1 }g"

                                        }

                                    ]

                                    resources = {

                                        "limits" = {

                                            "cpu"    = var.elastic_cpu_request
                                            "memory" = "${ var.elastic_memory_request }Gi"

                                        }

                                        "requests" = {

                                            "cpu"    = var.elastic_cpu_request
                                            "memory" = "${ var.elastic_memory_request }Gi"

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

                                    "ReadWriteOnce",

                                ]

                                "resources" = {

                                    "requests" = {

                                        "storage" = "${ var.disk_size_gb }Gi"

                                    }

                                }

                                "storageClassName" = "gp2"

                            }

                        },

                    ]

                }

            ]

        }

    }

}

resource "kubernetes_manifest" "kibana" {

    provider = kubernetes-alpha.k8

    manifest = {

        "apiVersion" = "kibana.k8s.elastic.co/v1"
        "kind"       = "Kibana"

        "metadata" = {

            namespace = var.namespace
            "name"    = var.cluster_name

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

                "spec" = {

                    "containers" = [

                        {

                            name = "kibana"

                            resources = {

                                "limits" = {

                                    "cpu"    = var.kibana_cpu_request
                                    "memory" = "${ var.kibana_memory_request }Gi"

                                }

                                "requests" = {

                                    "cpu"    = var.kibana_cpu_request
                                    "memory" = "${ var.kibana_memory_request }Gi"

                                }

                            }

                        }

                    ]

                }

            }

        }

    }

}
