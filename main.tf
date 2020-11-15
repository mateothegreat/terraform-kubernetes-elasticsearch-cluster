resource "kubernetes_manifest" "credentials" {

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

resource "kubernetes_manifest" "metricbeat" {

    manifest = {

        "apiVersion" = "beat.k8s.elastic.co/v1beta1"
        "kind"       = "Beat"

        "metadata" = {

            namespace = var.namespace
            "name"    = "metricbeat"

        }

        "spec" = {

            "type"    = "metricbeat"
            "version" = var.elastic_version

            "elasticsearchRef" = {

                "name" = var.cluster_name

            }

            "kibanaRef" = {

                "name" = var.cluster_name

            }

            "config" = {

                "metricbeat" = {

                    "autodiscover" = {

                        "providers" = [

                            {

                                hints = {

                                    "default_config" = {}
                                    "enabled"        = "true"

                                }

                                host = "$${NODE_NAME}"
                                type = "kubernetes"

                            },

                        ]

                    }

                    "modules" = [

                        {
                            metricsets = [

                                "cpu",
                                "load",
                                "memory",
                                "network",
                                "process",
                                "process_summary",

                            ]

                            module = "system"
                            period = "10s"

                            process = {

                                "include_top_n" = {

                                    "by_cpu"    = 5
                                    "by_memory" = 5

                                }

                            }

                            processes = [

                                ".*",

                            ]

                        },
                        {

                            metricsets = [

                                "filesystem",
                                "fsstat",

                            ]

                            module = "system"
                            period = "1m"

                            processors = [

                                {

                                    drop_event = {

                                        "when" = {

                                            "regexp" = {

                                                "system" = {

                                                    "filesystem" = {

                                                        "mount_point" = "^/(sys|cgroup|proc|dev|etc|host|lib)($|/)"

                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

                            ]

                        },
                        {

                            bearer_token_file = "/var/run/secrets/kubernetes.io/serviceaccount/token"
                            host              = "$${NODE_NAME}"
                            hosts             = [ "https://$${NODE_NAME}:10250" ]

                            metricsets = [

                                "node",
                                "system",
                                "pod",
                                "container",
                                "volume"

                            ]

                            module = "kubernetes"
                            period = "10s"
                            ssl    = {

                                "verification_mode" = "none"

                            }

                        }
                    ]

                }

                "processors" = [

                    {

                        add_cloud_metadata = {}

                    },

                    {

                        add_host_metadata = {}

                    },

                ]

            }

            "daemonSet" = {

                "podTemplate" = {

                    "spec" = {

                        "automountServiceAccountToken" = true

                        "containers" = [

                            {

                                args = [
                                    "-e",
                                    "-c",
                                    "/etc/beat.yml",
                                    "-system.hostfs=/hostfs",

                                ]

                                env = [

                                    {

                                        name      = "NODE_NAME"
                                        valueFrom = {

                                            "fieldRef" = {

                                                "fieldPath" = "spec.nodeName"

                                            }

                                        }

                                    }

                                ]

                                name = "metricbeat"

                                volumeMounts = [

                                    {

                                        mountPath = "/hostfs/sys/fs/cgroup"
                                        name      = "cgroup"

                                    },
                                    {

                                        mountPath = "/var/run/docker.sock"
                                        name      = "dockersock"

                                    },
                                    {

                                        mountPath = "/hostfs/proc"
                                        name      = "proc"

                                    }

                                ]

                            },

                        ]

                        "dnsPolicy"   = "ClusterFirstWithHostNet"
                        "hostNetwork" = true

                        "securityContext" = {

                            "runAsUser" = 0

                        }

                        "serviceAccountName"            = "metricbeat"
                        "terminationGracePeriodSeconds" = 30

                        "volumes" = [

                            {

                                hostPath = {

                                    "path" = "/sys/fs/cgroup"

                                }

                                name = "cgroup"

                            },
                            {

                                hostPath = {

                                    "path" = "/var/run/docker.sock"

                                }

                                name = "dockersock"

                            },
                            {

                                hostPath = {

                                    "path" = "/proc"

                                }

                                name = "proc"

                            },

                        ]

                    }

                }

            }

        }

    }

}
