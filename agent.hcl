data_dir  = "/var/log"
datacenter = "dc1"

bind_addr = "0.0.0.0" # the default

server {
  enabled = true
  bootstrap_expect = 1
}


client {

   enabled = true

    options = {
    "driver.allowlist" = "docker"
  }
  enabled = true
 servers = ["127.0.0.1:4647"]
  cpu_total_compute = 4200
}