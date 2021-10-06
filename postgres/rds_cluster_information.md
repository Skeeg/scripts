PGREADENDPOINT=$(aws rds describe-db-cluster-endpoints --filters "Name=db-cluster-endpoint-type,Values=READER" | jq -cr '.DBClusterEndpoints[].Endpoint')
pgbench -h "$PGREADENDPOINT" -c 100 --select-only -T 600 -C

RDSPROXYENDPOINT=$(aws rds describe-db-proxies | jq -cr '.DBProxies[].Endpoint')
python /home/ec2-user/simple_failover.py -e "$RDSPROXYENDPOINT" -u $DBUSER -p $DBPASS -d $PGDATABASE


Interesting data that can be gleaned from a table in the postgres/aurora databases:

```
select server_id, session_id, clock_timestamp(), pg_is_in_recovery(), inet_server_addr(), current_setting('transaction_read_only') from aurora_replica_status() where session_id = 'MASTER_SESSION_ID';
```

This gives you the details about what actual backend instance you are connected to in a given connection.

Since performance insights are only stored per-instance and you need to know the details if you want to look at that information selectively, it could be great to know from the app side what server is actually fulfilling your given query.

https://pluralsight.slack.com/archives/C1B3NE24E/p1629406979013200