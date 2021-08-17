job "python-hello" {
  datacenters = ["dc1"]
  type = "service"

  group "python-script" {
    count = 1

    
    task "python-test" {
      driver = "raw_exec"


      config {
        command = "python"
        args = ["/etc/nomad/scripts/hellorun.sh"]
      }

    }
}
}