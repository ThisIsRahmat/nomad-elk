# nomad-elk


To buid the dockerfile 

docker build -t {name of docker image} .  


To run the dockerfile this is specifically needed if you have a M1 Macbook like myself 

docker run --platform linux/amd64 -p 4646:4646 -p 9200:9200 -p 9300:9300 -p 5601:5601 --cap-add SYS_ADMIN {name of docker image}


After running the docker image you can access:

nomad: http://localhost:4646/
kibana: http://localhost:5601/

Current errors:

Elasticsearch is not running

Elasticsearch is installed in a patched way:
- I use an elasticsearch base but java still doesn't install so my work around was to have a script (java-elasticsearch) that installs java when docker
container is run. 
- I don't think this is the reason elasticsearch is not running, just giving some context

And I get the following logs when starting up kibana because elasticsearch doesn't run

  log   [22:23:41.911] [warning][elasticsearch] Unable to revive connection: http://localhost:9200/
  log   [22:23:41.916] [warning][elasticsearch] No living connections
  log   [22:23:44.455] [warning][elasticsearch] Unable to revive connection: http://localhost:9200/
  log   [22:23:44.465] [warning][elasticsearch] No living connections
  log   [22:23:47.076] [warning][elasticsearch] Unable to revive connection: http://localhost:9200/
  log   [22:23:47.091] [warning][elasticsearch] No living connections
  log   [22:23:49.609] [warning][elasticsearch] Unable to revive connection: http://localhost:9200/
  log   [22:23:49.628] [warning][elasticsearch] No living connections

