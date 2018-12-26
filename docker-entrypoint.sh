#!/bin/bash 

if [ -f "/usr/local/etc/initialized" ]; then
  echo "Initialized."
else
  echo "Initializing..."
  echo "Creating config files..."
  echo "Creating pool_hba.conf..."
  echo "
  # TYPE  DATABASE    USER        CIDR-ADDRESS          METHOD

  # "local" is for Unix domain socket connections only
  local   all         all                               trust
  # IPv4 local connections:
  host    all         all         127.0.0.1/32          trust
  host    all         all         ::1/128               trust
  host    all         all         0.0.0.0/0             md5
  " > /usr/local/etc/pool_hba.conf

  echo "Checking required environment variables..."

  for ENV_VAR in "MASTER_NODE_HOSTNAME" "REPLICA_NODE_HOSTNAME_0" "DB_NAME" "DB_USERNAME" "DB_PASSWORD"
  do
    if [ -z "${!ENV_VAR}" ]; then
      echo "$ENV_VAR is undefined. Please define it in /usr/local/etc/pgpool.conf" 
      if [ "$ENV_VAR" == "DB_USERNAME" -o "$ENV_VAR" == "DB_PASSWORD" ]; then
        echo "You are required to run 'pg_md5 -m -u <db_username> <db_password>' after they are defined in /usr/local/etc/pgpool.conf."
      fi
    fi
  done

  if [ "$CLUSTER_MODE" == "true" ]; then
    echo "Using Cluster mode"
    ENABLE_WATCHDOG=on

    for ENV_VAR in "AWS_ACCESS_KEY" "AWS_SECRET_KEY" "AWS_DEFAULT_REGION" "SELF_INSTANCE_ID" "ELASTIC_IP" "SELF_PRIVATE_IP" "STANDBY_INSTANCE_PRIVATE_IP"
    do
      if [ -z "${!ENV_VAR}" ]; then
        echo "$ENV_VAR is undefined. Please define it in /usr/local/etc/pgpool.conf" 
      fi
    done

    if [ -n "${AWS_ACCESS_KEY}" -a -n "${AWS_SECRET_KEY}" ]; then
      echo "Configuring AWS CLI..."
      mkdir ~/.aws
      echo "
[default]
region = ${AWS_DEFAULT_REGION}
      " > ~/.aws/config
      echo "
[default]
aws_access_key_id = ${AWS_ACCESS_KEY}
aws_secret_access_key = ${AWS_SECRET_KEY}
      " > ~/.aws/credentials
    fi

    if [ -n "${SELF_INSTANCE_ID}" -a -n "${ELASTIC_IP}" ]; then 
      echo 'Creating escalation script...'
      echo "
      #! /bin/bash
      echo "Assigning Elastic IP $ELASTIC_IP to instance $SELF_INSTANCE_ID"
      aws ec2 associate-address --instance-id ${SELF_INSTANCE_ID} --public-ip ${ELASTIC_IP}
      exit 0
      " > /usr/local/etc/aws-escalation.sh
      echo "
      #! /bin/bash
      echo "Disassociating Elastic IP $ELASTIC_UP"
      aws ec2 disassociate-address --public-ip $ELASTIC_IP
      exit 0
      " > /usr/local/etc/aws-de-escalation.sh

      chmod 777 /usr/local/etc/aws-*.sh
    fi
  else
    echo "Using single node"
    ENABLE_WATCHDOG=off
  fi

  echo "Create pgpool.conf..."
  echo "
  # ----------------------------
  # pgPool-II configuration file 
  # ----------------------------
  listen_addresses = '*'
  port = 9999
  socket_dir = '/tmp'
  listen_backlog_multiplier = 2
  serialize_accept = off
  pcp_listen_addresses = '*'
  pcp_port = 9898
  pcp_socket_dir = '/tmp'
  backend_hostname0 = '$MASTER_NODE_HOSTNAME'
  backend_port0 = ${MASTER_NODE_PORT:-5432}
  backend_weight0 = 1
  backend_data_directory0 = '/var/lib/pgsql/data'
  backend_flag0 = 'ALWAYS_MASTER'
  backend_hostname1 = '$REPLICA_NODE_HOSTNAME_0'
  backend_port1 = ${REPLICA_NODE_PORT:-5432}
  backend_weight1 = 1
  backend_data_directory1 = '/data1'
  backend_flag1 = 'ALLOW_TO_FAILOVER'
  enable_pool_hba = on
  pool_passwd = 'pool_passwd'
  authentication_timeout = 60
  allow_clear_text_frontend_auth = off

  # - SSL Connections -

  ssl = off
                                    # Enable SSL support
                                    # (change requires restart)
  #ssl_key = './server.key'
                                    # Path to the SSL private key file
                                    # (change requires restart)
  #ssl_cert = './server.cert'
                                    # Path to the SSL public certificate file
                                    # (change requires restart)
  #ssl_ca_cert = ''
                                    # Path to a single PEM format file
                                    # containing CA root certificate(s)
                                    # (change requires restart)
  #ssl_ca_cert_dir = ''
                                    # Directory containing CA root certificate(s)
                                    # (change requires restart)

  num_init_children = 32
  max_pool = 4
  child_life_time = 300
  child_max_connections = 0
  connection_life_time = 0
  client_idle_limit = 0
  log_destination = 'stderr'
  log_line_prefix = '%t: pid %p: ' 
  log_connections = off
  log_hostname = off
  log_statement = off
  log_per_node_statement = off
  log_client_messages = off
  log_standby_delay = 'none'
  syslog_facility = 'LOCAL0'
  syslog_ident = 'pgpool'
  pid_file_name = '/var/run/pgpool/pgpool.pid'
  logdir = '/var/log/pgpool'
  connection_cache = on
  reset_query_list = 'ABORT; DISCARD ALL'
  replication_mode = off
  replicate_select = off
  insert_lock = on
  lobj_lock_table = ''
  replication_stop_on_mismatch = off
  failover_if_affected_tuples_mismatch = off
  load_balance_mode = on
  ignore_leading_white_space = on
  white_function_list = ''
  black_function_list = 'currval,lastval,nextval,setval'
  black_query_pattern_list = ''
  database_redirect_preference_list = ''
  app_name_redirect_preference_list = ''
  allow_sql_comments = off
  disable_load_balance_on_write = 'transaction'
  master_slave_mode = on
  master_slave_sub_mode = 'stream'
  sr_check_period = 0
  sr_check_user = 'nobody'
  sr_check_password = ''
  sr_check_database = 'postgres'
  delay_threshold = 0
  follow_master_command = ''
  health_check_period = 0
  health_check_timeout = 20
  health_check_user = '$DB_USERNAME'
  health_check_password = '$DB_PASSWORD'
  health_check_database = '$DB_NAME'
  health_check_max_retries = 20
  health_check_retry_delay = 1
  connect_timeout = 10000
  health_check_period0 = 5
  health_check_timeout0 = 20
  health_check_user0 = '$DB_USERNAME'
  health_check_password0 = '$DB_PASSWORD'
  health_check_database0 = '$DB_NAME'
  health_check_max_retries0 = 20
  health_check_retry_delay0 = 1
  connect_timeout0 = 10000
  failover_command = ''
  failback_command = ''
  failover_on_backend_error = off
  detach_false_primary = off
  search_primary_node_timeout = 300
  recovery_user = 'nobody'
  recovery_password = ''
  recovery_1st_stage_command = ''
  recovery_2nd_stage_command = ''
  recovery_timeout = 90
  client_idle_limit_in_recovery = 0
  use_watchdog = $ENABLE_WATCHDOG
  trusted_servers = ''
  ping_path = '/bin'
  wd_hostname = '$SELF_PRIVATE_IP'
  wd_port = 9000
  wd_priority = 1
  wd_authkey = ''
  wd_ipc_socket_dir = '/tmp'
  delegate_IP = ''
  other_pgpool_hostname0 = '$STANDBY_INSTANCE_PRIVATE_IP'
  other_pgpool_port0 = 9999
  other_wd_port0 = 9000
  if_cmd_path = '/sbin'
  if_up_cmd = 'ip addr add $_IP_$/24 dev eth0 label eth0:0'
  if_down_cmd = 'ip addr del $_IP_$/24 dev eth0'
  arping_path = '/usr/sbin'
  arping_cmd = 'arping -U $_IP_$ -w 1'
  clear_memqcache_on_escalation = on
  wd_escalation_command = '/usr/local/etc/aws-escalation.sh'
  wd_de_escalation_command = '/usr/local/etc/aws-de-escalation.sh'
  failover_when_quorum_exists = on
  failover_require_consensus = on
  allow_multiple_failover_requests_from_node = off
  wd_monitoring_interfaces_list = ''
  wd_lifecheck_method = 'heartbeat'
  wd_interval = 10
  wd_heartbeat_port = 9694
  wd_heartbeat_keepalive = 2
  wd_heartbeat_deadtime = 30
  heartbeat_destination0 = '$STANDBY_INSTANCE_PRIVATE_IP'
  heartbeat_destination_port0 = 9694 
  heartbeat_device0 = ''
  wd_life_point = 3
  wd_lifecheck_query = 'SELECT 1'
  wd_lifecheck_dbname = 'template1'
  wd_lifecheck_user = 'nobody'
  wd_lifecheck_password = ''
  relcache_expire = 0
  relcache_size = 256
  check_temp_table = on
  check_unlogged_table = on
  memory_cache_enabled = off
  memqcache_method = 'shmem'
  memqcache_memcached_host = 'localhost'
  memqcache_memcached_port = 11211
  memqcache_total_size = 67108864
  memqcache_max_num_cache = 1000000
  memqcache_expire = 0
  memqcache_auto_cache_invalidation = on
  memqcache_maxcache = 409600
  memqcache_cache_block_size = 1048576
  memqcache_oiddir = '/var/log/pgpool/oiddir'
  white_memqcache_table_list = ''
  black_memqcache_table_list = ''
  " > /usr/local/etc/pgpool.conf

  if [ -n "${DB_USERNAME}" -a -n "${DB_PASSWORD}" ]; then 
    echo 'Creating md5 auth entry for PgPool...'
    pg_md5 -m -u ${DB_USERNAME} ${DB_PASSWORD}
  fi

  touch /usr/local/etc/initialized
fi

if [ -f "/var/run/pgpool/pgpool.pid" ]; then
  rm /var/run/pgpool/pgpool.pid
  fuser -k 9999/tcp 9000/tcp
fi

pgpool -n