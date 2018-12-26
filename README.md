# PGpool-II Docker Image For AWS RDS Load Balancing

This image build PGpool-II from source on top of Ubuntu 18.04 LTS. 

This repo comes with sample config files to achieve load balancing 
and connection pooling of your AWS RDS for PostgreSQL. 


__Versions:__
- PGpool-II: v4.0.2
- Ubuntu: 18.04 LTS
- Postgres: 10

## How to use this image?

```sh
docker run -it -e "REPLICA_NODE_HOSTNAME_0=<replica_node_hostname>" -e "MASTER_NODE_HOSTNAME=<master_node_hostname>" -e "DB_NAME=<database_name>" -e "DB_USERNAME=<database_username>" -e "DB_PASSWORD=<database_password>" pgpool:1.0
```

## Using it with Docker Compose

TODO

## Environment Variables

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
|AWS_DEFAULT_REGION| Your default AWS region, refer to (https://docs.aws.amazon.com/general/latest/gr/rande.html)[here]| No, unless in cluster mode |
|ELASTIC_IP| Your PgPool-II Cluster public IP | No, unless in cluster mode |
|SELF_INSTANCE_ID| AWS instance ID this image is running on | No, unless in cluster mode |
|SELF_PRIVATE_IP| AWS private IP of the instance this image is running on | No, unless in cluster mode |
|STANDBY_INSTANCE_PRIVATE_IP| AWS private IP of the standby instance | No, unless in cluster mode |

## Creating a PgPool-II Cluster

TODO 

[source](http://www.pgpool.net/docs/latest/en/html/example-aws.html)

## Logs

TODO
where does the logs live?

## Testing

### Test Load Balancing

TODO
