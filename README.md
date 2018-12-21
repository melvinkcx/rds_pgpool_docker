# PGpool-II Docker Image With Config Files For AWS RDS Load Balancing

This image build PGpool-II from source on top of Ubuntu 18.04 LTS. 

This repo comes with sample config files to achieve load balancing 
and connection pooling of your AWS RDS for PostgreSQL. 

__Versions:__
- PGpool-II: v4.0.2
- Ubuntu: 18.04 LTS
- Postgres: 10

## How to use this image?
Supply environment variables

## Environment Variable
|---|---|--------|
|Variable|Description|Required?|
|---|---|--------|
|MASTER_NODE_HOSTNAME | Eg: test-node0.xxxxxxxxx.rds.amazonaws.com | Yes |
|MASTER_NODE_PORT | Default is 5432 | No |
|REPLICA_NODE_HOSTNAME_0 | Eg: test-node1.xxxxxxxxx.rds.amazonaws.com | Yes |
|REPLICA_NODE_PORT | Default is 5432 | No |
|DB_NAME | Database Name, default is 'postgres' | Yes |
|DB_USERNAME | Username of the Master Node, this will also be used as PGPOOL credentials | Yes |
|DB_PASSWORD | Password of the Master Node, this will also be used as PGPOOL credentials | Yes |
