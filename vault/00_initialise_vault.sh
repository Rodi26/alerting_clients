cat > ../configuration/vault.hcl << EOF
ui = true
disable_mlock = true

storage "raft" {
  path = "$(home)vault"
  node_id = "raft_node_1"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable = "true"
}

api_addr = "http://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"


license_path = "$(home)/license/vault.hclic"

telemetry {
  disable_hostname = true
  prometheus_retention_time = "12h"
}

mkdir -p $(home)/vault
