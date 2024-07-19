vault policy write prometheus-metrics - << EOF
path "/sys/metrics" {
  capabilities = ["read"]
}
EOF

vault token create \
  -field=token \
  -policy prometheus-metrics \
  > ../configuration/prometheus-token


cat > ../configuration/prometheus.yml << EOF
# my global config
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.
  evaluation_interval: 15s # By default, scrape targets every 15 seconds.
  # scrape_timeout is set to the global default (10s).

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
      monitor: 'my-project'

# Load and evaluate rules in this file every 'evaluation_interval' seconds.
rule_files:
  - 'alert.rules'
  # - "first.rules"
  # - "second.rules"
scrape_configs:
  - job_name: vault
    metrics_path: "/v1/sys/metrics"
    params:
      format: ['prometheus']
    scheme: http
    authorization:
      credentials_file: /etc/prometheus/prometheus-token
    static_configs:
    - targets: ['host.docker.internal:8200']
alerting:
  alertmanagers:
    - static_configs:
      - targets: ['host.docker.internal:9093']
EOF

docker pull prom/prometheus

docker run \
    --detach \
    --name vault-prometheus \
    -p 9090:9090 \
    --rm \
    --volume $(pwd)/configuration/prometheus.yml:/etc/prometheus/prometheus.yml \
    --volume $(pwd)/configuration/alert.rules:/etc/prometheus/alert.rules \
    --volume  $(pwd)/configuration/prometheus-token:/etc/prometheus/prometheus-token \
    --volume /Users/rodolphe/vault/prometheus:/prometheus \
    prom/prometheus

cat > ../configuration/alertmanager.yml << EOF
  global:
    slack_api_url: $(echo $slack_api_url)
  route:
    receiver: 'slack'

  receivers:
  - name: 'slack'
    slack_configs:
    - send_resolved: false
      channel: '#allerting'
      text: "summary: {{ .CommonAnnotations.summary }}"
EOF

docker pull prom/alertmanager

docker run \
    --detach \
    --name vault-alertmanager \
    -p 9093:9093 \
    --rm \
    --volume $(pwd)/configuration/alertmanager.yml:/etc/alertmanager/alertmanager.yml \
    prom/alertmanager



cat > $(pwd)/configuration/datasource.yml << EOF
# config file version
apiVersion: 1

datasources:
- name: vault
  type: prometheus
  access: server
  orgId: 1
  url: http://host.docker.internal:9090
  password:
  user:
  database:
  basicAuth:
  basicAuthUser:
  basicAuthPassword:
  withCredentials:
  isDefault:
  jsonData:
     graphiteVersion: "1.1"
     tlsAuth: false
     tlsAuthWithCACert: false
  secureJsonData:
    tlsCACert: ""
    tlsClientCert: ""
    tlsClientKey: ""
  version: 1
  editable: true
EOF

docker pull grafana/grafana:latest

docker run \
    --detach \
    --name vault-grafana \
    -p 3000:3000 \
    --rm \
    --volume $(pwd)/configuration/datasource.yml:/etc/grafana/provisioning/datasources/prometheus_datasource.yml \
    --volume /Users/rodolphe/vault/grafana:/var/lib/grafana \
    grafana/grafana
