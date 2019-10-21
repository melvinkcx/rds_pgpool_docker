# RDS_PGPOOL v0.2.6 - PgPool-II Docker Image For AWS RDS Load Balancing


This image builds PgPool-II from source on top of Ubuntu 18.04 LTS. 

rds_pgpool comes with configuration files for load balancing and connection pooling for AWS RDS for PostgresQL.

__Latest image version__: `v0.2.6` 

> Do NOT use any version before v0.2.6


__Packages versions:__
- PgPool-II: v4.0.6
- Ubuntu: 18.04 LTS
- Postgres: 10 (We need this to build PgPool-II)


## Single-node Mode vs Cluster Mode

PgPool-II supports both single-node mode and cluster mode. In cluster mode, watchdogs of all nodes will monitor each other and will elect another master if the master node is down.

This image assumes:

- PgPool-II runs as a 2-node cluster;
- AWS RDS is used;
- AWS RDS is a 2-node database cluster (1 master and 1 read replica).

If you are having more than 2 nodes, you can still add them into the cluster by modifying `/usr/local/etc/pgpool.conf`. Consult [official documentation](http://www.pgpool.net/docs/latest/en/html/runtime-config.html) for more configurations.


## Running in Single-Node Mode

### Prerequisite
None

### Run with Docker Compose

In rds_pgpool, it is Single-Node mode by default.

Assuming these are our database attributes:

- Master DB Hostname: xxxx.xxxx.ap-southeast-1.rds.amazonaws.com
- Slave DB Hostname: yyyy.yyyy.ap-southeast-1.rds.amazonaws.com
- Database name: postgres
- Database username: postgres
- Database password: postgres

__docker-compose.yml__ would be:

```
version: "3"
services: 
  pgpool:
    restart: 'always'
    image: melvinkcx/rds_pgpool:0.2.6
    ports:
      - "9999:9999"
      - "9000:9000"
      - "9694:9694"
    environment:
      - DB_NAME=postgres
      - DB_USERNAME=postgres
      - DB_PASSWORD=postgres
      - MASTER_NODE_HOSTNAME=xxxx.xxxx.ap-southeast-1.rds.amazonaws.com
      - REPLICA_NODE_HOSTNAME_0=yyyy.yyyy.ap-southeast-1.rds.amazonaws.com
```

## Running in Cluster Mode

### Prerequisite
This image assumes a 2-node cluster, you are required to create 2 EC2 instances and allocate 1 Elastic IP. You will need the `instance-id` and `instance private IP` of both nodes. 


### Run with Docker Compose

In rds_pgpool, cluster mode is enabled by setting `CLUSTER_MODE` to `true`. Refer to section __Environment Variables__ below, read through the list of supported variables, and supply with relevant values.

Assuming these are the instance-ids and ips:

- Node 1 instance id: i-ababababab
- Node 1 private IP: 172.33.11.11
- Node 2 instance id: i-xyxyxyxy
- Node 2 private IP: 172.33.33.33
- Elastic IP: 55.55.55.55

and these are our database attributes:

- Master DB Hostname: xxxx.xxxx.ap-southeast-1.rds.amazonaws.com
- Slave DB Hostname: yyyy.yyyy.ap-southeast-1.rds.amazonaws.com
- Database name: postgres
- Database username: postgres
- Database password: postgres


__docker-compose.yml for Node 1__

```
version: "3"
services: 
  pgpool:
    restart: 'always'
    image: melvinkcx/rds_pgpool:0.2.6
    ports:
      - "9999:9999"
      - "9000:9000"
      - "9694:9694"
    environment:
      - DB_NAME=postgres
      - DB_USERNAME=postgres
      - DB_PASSWORD=postgres
      - MASTER_NODE_HOSTNAME=xxxx.xxxx.ap-southeast-1.rds.amazonaws.com
      - REPLICA_NODE_HOSTNAME_0=yyyy.yyyy.ap-southeast-1.rds.amazonaws.com
      - CLUSTER_MODE=true
      - AWS_ACCESS_KEY=<your aws access key>
      - AWS_SECRET_KEY=<your aws secret key>
      - AWS_DEFAULT_REGION=<your aws ec2 default region>
      - ELASTIC_IP=55.55.55.55
      - SELF_INSTANCE_ID=i-abababab
      - SELF_PRIVATE_IP=172.33.11.11
      - STANDBY_INSTANCE_PRIVATE_IP=172.33.33.33
```


__docker-compose.yml for Node 2__

```
version: "3"
services: 
  pgpool:
    restart: 'always'
    image: melvinkcx/rds_pgpool:0.2.6
    ports:
      - "9999:9999"
      - "9000:9000"
      - "9694:9694"
    environment:
      - DB_NAME=postgres
      - DB_USERNAME=postgres
      - DB_PASSWORD=postgres
      - MASTER_NODE_HOSTNAME=xxxx.xxxx.ap-southeast-1.rds.amazonaws.com
      - REPLICA_NODE_HOSTNAME_0=yyyy.yyyy.ap-southeast-1.rds.amazonaws.com
      - CLUSTER_MODE=true
      - AWS_ACCESS_KEY=<your aws access key>
      - AWS_SECRET_KEY=<your aws secret key>
      - AWS_DEFAULT_REGION=<your aws ec2 default region>
      - ELASTIC_IP=55.55.55.55
      - SELF_INSTANCE_ID=i-xyxyxyxy
      - SELF_PRIVATE_IP=172.33.33.33
      - STANDBY_INSTANCE_PRIVATE_IP=172.33.11.11
```

In each instance, run `docker-compose up -d`


## Environment Variables
These environment variables control the behavior of PgPool-II. 

> Config files are initailized when container is created. Any subsequent change will not be updated. Please remove and rebuild the container if any environment variables is changed. 

|Variable|Description|Required?|
|---|---|--------|
|MASTER_NODE_HOSTNAME | Eg: test-node0.xxxxxxxxx.rds.amazonaws.com | Yes |
|MASTER_NODE_PORT | Default is 5432 | No |
|REPLICA_NODE_HOSTNAME_0 | Eg: test-node1.xxxxxxxxx.rds.amazonaws.com | Yes |
|REPLICA_NODE_PORT | Default is 5432 | No |
|DB_NAME | Database Name, default is 'postgres' | Yes |
|DB_USERNAME | Username of the Master Node, this will also be used as credential for PgPool-II | Yes |
|DB_PASSWORD | Password of the Master Node, this will also be used as PGPOOL credential for PgPool-II | Yes |
|CLUSTER_MODE| `true` or `false`, default is `false` | No | 
|AWS_ACCESS_KEY | Your AWS user access key | No, unless in cluster mode |
|AWS_SECRET_KEY| Your AWS user secret access key | No, unless in cluster mode |
|AWS_DEFAULT_REGION| Your default AWS region, refer to [here](https://docs.aws.amazon.com/general/latest/gr/rande.html)| No, unless in cluster mode |
|ELASTIC_IP| Your PgPool-II Cluster public IP | No, unless in cluster mode |
|SELF_INSTANCE_ID| AWS instance ID this image is running on | No, unless in cluster mode |
|SELF_PRIVATE_IP| AWS private IP of the instance this image is running on | No, unless in cluster mode |
|STANDBY_INSTANCE_PRIVATE_IP| AWS private IP of the standby instance | No, unless in cluster mode |
|NUM_INIT_CHILDREN| Maximum number of child process, default to 32 | Recommended|
|MAX_POOL| Maximum connection cache per child, default to 4 | Recommended|

## Connecting To PgPool-II
To connect to PgPool-II, re-configure your client apps to connect to the PgPool-II cluster with port `9999` instead of your database instance directly. 

For instance, the Elastic IP assigned to your PgPool-II cluster is `55.55.55.55`, the database connection for all your client applications should be `55.55.55.55:9999`

## Testing

### Test Load Balancing

To test load balancing, shell into your Docker container and run this to simulate read requests:

```sh
pgbench -h localhost -p 9999 -U <username> -c 10 -T 10 -S
```

To see the number of requests being dispatched to each node, run:

```sh
psql -h localhost -p 9999 -U <username> -W -c "show pool_nodes"
```

### Test PgPool-II Failover

1. Make sure PgPool-II in both nodes/instances are up and running.
2. Run `docker logs <your_container_id> -f` to monitor the log.
3. Manually stop or reboot the Master PgPool-II node. (It should be the one with your Elastic IP attached. In our case, Node 1 is stopped.)
4. Observe the logs of Node 2. 
5. Check the associated instance of your Elastic IP, it should now be assigned to Node 2.

[![Deepin-Screenshot-20181226172051.png](https://i.postimg.cc/NGrLLQ2s/Deepin-Screenshot-20181226172051.png)](https://postimg.cc/ThfT4McF)

## FAQ

### Why are AWS access key and secret needed?

PgPool-II uses AWS CLI to associate Elastic IP when the master node is down. In order to use AWS CLI, access keys must be configured. If you are not using Cluster Mode, you can safely ignore it.

### What if I have more than 2 nodes?
If you have more than 2 nodes, consult the [documentation](http://www.pgpool.net/docs/latest/en/html/runtime-config.html) to learn what to configure in `/usr/local/etc/pgpool.conf`.

## Troubleshooting

### It says 'remaining connection slots are reserved for non-replication superuser connections' OR 'kind does not match between master(xx) slot[x] (xx)'.

Your PgPool-II init children are more than your master node max connection. 

How to view max connections of my Postgres:

```
show max_connections;

 max_connections 
-----------------
 26
(1 row)
```

Max usable is 26 - 3 (reserved for superuser connection) = 23

If you pool size is 4, your children should not be more than 23 / 4 ~= 5.