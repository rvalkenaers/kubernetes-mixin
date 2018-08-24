local g = import 'grafana-builder/grafana.libsonnet';

{
  grafanaDashboards+:: {
    'k8s-resources-cluster.json':
      local tableStyles = {
        namespace: {
          alias: 'Namespace',
          link: '%(prefix)s/d/%(uid)s/k8s-resources-namespace?var-datasource=$datasource&var-namespace=$__cell' % { prefix: $._config.grafanaPrefix, uid: std.md5('k8s-resources-namespace.json') },
        },
      };

      g.dashboard(
        'K8s / Compute Resources / Cluster',
        uid=($._config.grafanaDashboardIDs['k8s-resources-cluster.json']),
      ).addTemplate('cluster', 'kube_pod_info', 'cluster')
      .addRow(
        (g.row('Headlines') +
         {
           height: '100px',
           showTitle: false,
         })
         .addPanel(
           g.panel('CPU Utilisation') +
           g.statPanel(':node_cpu_utilisation:avg1m{cluster="$cluster"}')
         )
        .addPanel(
          g.panel('CPU Requests Commitment') +
          g.statPanel('sum(kube_pod_container_resource_requests_cpu_cores{cluster="$cluster"}) / sum(node:node_num_cpu:sum{cluster="$cluster"})')
        )
        .addPanel(
          g.panel('CPU Limits Commitment') +
          g.statPanel('sum(kube_pod_container_resource_limits_cpu_cores{cluster="$cluster"}) / sum(node:node_num_cpu:sum{cluster="$cluster"})')
        )
        .addPanel(
          g.panel('Memory Utilisation') +
          g.statPanel(':node_memory_utilisation:{cluster="$cluster"}')
        )
        .addPanel(
          g.panel('Memory Requests Commitment') +
          g.statPanel('sum(kube_pod_container_resource_requests_memory_bytes{cluster="$cluster"}) / sum(node_memory_MemTotal{cluster="$cluster"})')
        )
        .addPanel(
          g.panel('Memory Limits Commitment') +
          g.statPanel('sum(kube_pod_container_resource_limits_memory_bytes{cluster="$cluster"}) / sum(node_memory_MemTotal{cluster="$cluster"})')
        )
      )
      .addRow(
        g.row('CPU')
        .addPanel(
          g.panel('CPU Usage') +
          g.queryPanel('sum(irate(container_cpu_usage_seconds_total{cluster="$cluster"}[1m])) by (namespace)', '{{namespace}}') +
          g.stack
        )
      )
      .addRow(
        g.row('CPU Quota')
        .addPanel(
          g.panel('CPU Quota') +
          g.tablePanel([
            'sum(rate(container_cpu_usage_seconds_total{cluster="$cluster"}[5m])) by (namespace)',
            'sum(kube_pod_container_resource_requests_cpu_cores{cluster="$cluster"}) by (namespace)',
            'sum(rate(container_cpu_usage_seconds_total{cluster="$cluster"}[5m])) by (namespace) / sum(kube_pod_container_resource_requests_cpu_cores{cluster="$cluster"}) by (namespace)',
            'sum(kube_pod_container_resource_limits_cpu_cores{cluster="$cluster"}) by (namespace)',
            'sum(rate(container_cpu_usage_seconds_total{cluster="$cluster"}[5m])) by (namespace) / sum(kube_pod_container_resource_limits_cpu_cores{cluster="$cluster"}) by (namespace)',
          ], tableStyles {
            'Value #A': { alias: 'CPU Usage' },
            'Value #B': { alias: 'CPU Requests' },
            'Value #C': { alias: 'CPU Requests %', unit: 'percentunit' },
            'Value #D': { alias: 'CPU Limits' },
            'Value #E': { alias: 'CPU Limits %', unit: 'percentunit' },
          })
        )
      )
      .addRow(
        g.row('Memory')
        .addPanel(
          g.panel('Memory Usage (w/o cache)') +
          // Not using container_memory_usage_bytes here because that includes page cache
          g.queryPanel('sum(container_memory_rss{cluster="$cluster"}) by (namespace)', '{{namespace}}') +
          g.stack +
          { yaxes: g.yaxes('decbytes') },
        )
      )
      .addRow(
        g.row('Memory Requests')
        .addPanel(
          g.panel('Requests by Namespace') +
          g.tablePanel([
            // Not using container_memory_usage_bytes here because that includes page cache
            'sum(container_memory_rss{cluster="$cluster"}) by (namespace)',
            'sum(kube_pod_container_resource_requests_memory_bytes{cluster="$cluster"}) by (namespace)',
            'sum(container_memory_rss{cluster="$cluster"}) by (namespace) / sum(kube_pod_container_resource_requests_memory_bytes{cluster="$cluster"}) by (namespace)',
            'sum(kube_pod_container_resource_limits_memory_bytes{cluster="$cluster"}) by (namespace)',
            'sum(container_memory_rss{cluster="$cluster"}) by (namespace) / sum(kube_pod_container_resource_limits_memory_bytes{cluster="$cluster"}) by (namespace)',
          ], tableStyles {
            'Value #A': { alias: 'Memory Usage', unit: 'decbytes' },
            'Value #B': { alias: 'Memory Requests', unit: 'decbytes' },
            'Value #C': { alias: 'Memory Requests %', unit: 'percentunit' },
            'Value #D': { alias: 'Memory Limits', unit: 'decbytes' },
            'Value #E': { alias: 'Memory Limits %', unit: 'percentunit' },
          })
        )
      ),

    'k8s-resources-namespace.json':
      local tableStyles = {
        pod: {
          alias: 'Pod',
          link: '%(prefix)s/d/%(uid)s/k8s-resources-pod?var-datasource=$datasource&var-namespace=$namespace&var-pod=$__cell' % { prefix: $._config.grafanaPrefix, uid: std.md5('k8s-resources-pod.json') },
        },
      };

      g.dashboard(
        'K8s / Compute Resources / Namespace',
        uid=($._config.grafanaDashboardIDs['k8s-resources-namespace.json']),
      ).addTemplate('cluster', 'kube_pod_info', 'cluster')
      .addTemplate('namespace', 'kube_pod_info{cluster="$cluster"}', 'namespace')
      .addRow(
        g.row('CPU Usage')
        .addPanel(
          g.panel('CPU Usage') +
          g.queryPanel('sum(irate(container_cpu_usage_seconds_total{cluster="$cluster", namespace="$namespace"}[1m])) by (pod_name)', '{{pod_name}}') +
          g.stack,
        )
      )
      .addRow(
        g.row('CPU Quota')
        .addPanel(
          g.panel('CPU Quota') +
          g.tablePanel([
            'sum(label_replace(rate(container_cpu_usage_seconds_total{cluster="$cluster", namespace="$namespace"}[5m]), "pod", "$1", "pod_name", "(.*)")) by (pod)',
            'sum(kube_pod_container_resource_requests_cpu_cores{cluster="$cluster", namespace="$namespace"}) by (pod)',
            'sum(label_replace(rate(container_cpu_usage_seconds_total{cluster="$cluster", namespace="$namespace"}[5m]), "pod", "$1", "pod_name", "(.*)")) by (pod) / sum(kube_pod_container_resource_requests_cpu_cores{cluster="$cluster", namespace="$namespace"}) by (pod)',
            'sum(kube_pod_container_resource_limits_cpu_cores{cluster="$cluster", namespace="$namespace"}) by (pod)',
            'sum(label_replace(rate(container_cpu_usage_seconds_total{cluster="$cluster", namespace="$namespace"}[5m]), "pod", "$1", "pod_name", "(.*)")) by (pod) / sum(kube_pod_container_resource_limits_cpu_cores{cluster="$cluster", namespace="$namespace"}) by (pod)',
          ], tableStyles {
            'Value #A': { alias: 'CPU Usage' },
            'Value #B': { alias: 'CPU Requests' },
            'Value #C': { alias: 'CPU Requests %', unit: 'percentunit' },
            'Value #D': { alias: 'CPU Limits' },
            'Value #E': { alias: 'CPU Limits %', unit: 'percentunit' },
          })
        )
      )
      .addRow(
        g.row('Memory Usage')
        .addPanel(
          g.panel('Memory Usage') +
          g.queryPanel('sum(container_memory_usage_bytes{cluster="$cluster", namespace="$namespace"}) by (pod_name)', '{{pod_name}}') +
          g.stack,
        )
      )
      .addRow(
        g.row('Memory Quota')
        .addPanel(
          g.panel('Memory Quota') +
          g.tablePanel([
            'sum(label_replace(container_memory_usage_bytes{cluster="$cluster", namespace="$namespace"}, "pod", "$1", "pod_name", "(.*)")) by (pod)',
            'sum(kube_pod_container_resource_requests_memory_bytes{cluster="$cluster", namespace="$namespace"}) by (pod)',
            'sum(label_replace(container_memory_usage_bytes{cluster="$cluster", namespace="$namespace"}, "pod", "$1", "pod_name", "(.*)")) by (pod) / sum(kube_pod_container_resource_requests_memory_bytes{cluster="$cluster", namespace="$namespace"}) by (pod)',
            'sum(kube_pod_container_resource_limits_memory_bytes{cluster="$cluster", namespace="$namespace"}) by (pod)',
            'sum(label_replace(container_memory_usage_bytes{cluster="$cluster", namespace="$namespace"}, "pod", "$1", "pod_name", "(.*)")) by (pod) / sum(kube_pod_container_resource_limits_memory_bytes{cluster="$cluster", namespace="$namespace"}) by (pod)',
          ], tableStyles {
            'Value #A': { alias: 'Memory Usage', unit: 'decbytes' },
            'Value #B': { alias: 'Memory Requests', unit: 'decbytes' },
            'Value #C': { alias: 'Memory Requests %', unit: 'percentunit' },
            'Value #D': { alias: 'Memory Limits', unit: 'decbytes' },
            'Value #E': { alias: 'Memory Limits %', unit: 'percentunit' },
          })
        )
      ),

    'k8s-resources-pod.json':
      local tableStyles = {
        container: {
          alias: 'Container',
        },
      };

      g.dashboard(
        'K8s / Compute Resources / Pod',
        uid=($._config.grafanaDashboardIDs['k8s-resources-pod.json']),
      ).addTemplate('cluster', 'kube_pod_info', 'cluster')
      .addTemplate('namespace', 'kube_pod_info{cluster="$cluster"}', 'namespace')
      .addTemplate('pod', 'kube_pod_info{cluster="$cluster",namespace="$namespace"}', 'pod')
      .addRow(
        g.row('CPU Usage')
        .addPanel(
          g.panel('CPU Usage') +
          g.queryPanel('sum(irate(container_cpu_usage_seconds_total{cluster="$cluster", namespace="$namespace", pod_name="$pod", container_name!="POD"}[1m])) by (container_name)', '{{container_name}}') +
          g.stack,
        )
      )
      .addRow(
        g.row('CPU Quota')
        .addPanel(
          g.panel('CPU Quota') +
          g.tablePanel([
            'sum(label_replace(rate(container_cpu_usage_seconds_total{cluster="$cluster", namespace="$namespace", pod_name="$pod", container_name!="POD"}[5m]), "container", "$1", "container_name", "(.*)")) by (container)',
            'sum(kube_pod_container_resource_requests_cpu_cores{cluster="$cluster", namespace="$namespace", pod="$pod"}) by (container)',
            'sum(label_replace(rate(container_cpu_usage_seconds_total{cluster="$cluster", namespace="$namespace", pod_name="$pod"}[5m]), "container", "$1", "container_name", "(.*)")) by (container) / sum(kube_pod_container_resource_requests_cpu_cores{cluster="$cluster", namespace="$namespace", pod="$pod"}) by (container)',
            'sum(kube_pod_container_resource_limits_cpu_cores{cluster="$cluster", namespace="$namespace", pod="$pod"}) by (container)',
            'sum(label_replace(rate(container_cpu_usage_seconds_total{cluster="$cluster", namespace="$namespace", pod_name="$pod"}[5m]), "container", "$1", "container_name", "(.*)")) by (container) / sum(kube_pod_container_resource_limits_cpu_cores{cluster="$cluster", namespace="$namespace", pod="$pod"}) by (container)',
          ], tableStyles {
            'Value #A': { alias: 'CPU Usage' },
            'Value #B': { alias: 'CPU Requests' },
            'Value #C': { alias: 'CPU Requests %', unit: 'percentunit' },
            'Value #D': { alias: 'CPU Limits' },
            'Value #E': { alias: 'CPU Limits %', unit: 'percentunit' },
          })
        )
      )
      .addRow(
        g.row('Memory Usage')
        .addPanel(
          g.panel('Memory Usage') +
          g.queryPanel('sum(container_memory_usage_bytes{cluster="$cluster", namespace="$namespace", pod_name="$pod", container_name!="POD"}) by (container_name)', '{{container_name}}') +
          g.stack,
        )
      )
      .addRow(
        g.row('Memory Quota')
        .addPanel(
          g.panel('Memory Quota') +
          g.tablePanel([
            'sum(label_replace(container_memory_usage_bytes{cluster="$cluster", namespace="$namespace", pod_name="$pod", container_name!="POD"}, "container", "$1", "container_name", "(.*)")) by (container)',
            'sum(kube_pod_container_resource_requests_memory_bytes{cluster="$cluster", namespace="$namespace", pod="$pod"}) by (container)',
            'sum(label_replace(container_memory_usage_bytes{cluster="$cluster", namespace="$namespace", pod_name="$pod"}, "container", "$1", "container_name", "(.*)")) by (container) / sum(kube_pod_container_resource_requests_memory_bytes{cluster="$cluster", namespace="$namespace", pod="$pod"}) by (container)',
            'sum(kube_pod_container_resource_limits_memory_bytes{cluster="$cluster", namespace="$namespace", pod="$pod"}) by (container)',
            'sum(label_replace(container_memory_usage_bytes{cluster="$cluster", namespace="$namespace", pod_name="$pod"}, "container", "$1", "container_name", "(.*)")) by (container) / sum(kube_pod_container_resource_limits_memory_bytes{cluster="$cluster", namespace="$namespace", pod="$pod"}) by (container)',
          ], tableStyles {
            'Value #A': { alias: 'Memory Usage', unit: 'decbytes' },
            'Value #B': { alias: 'Memory Requests', unit: 'decbytes' },
            'Value #C': { alias: 'Memory Requests %', unit: 'percentunit' },
            'Value #D': { alias: 'Memory Limits', unit: 'decbytes' },
            'Value #E': { alias: 'Memory Limits %', unit: 'percentunit' },
          })
        )
      ),
  },
}
