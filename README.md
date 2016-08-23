##Hadoop, Kafka, Druid Data Ingestion Lab
The purpose of this lab is to test data ingestion with a variety of open source tools. We will focus on these:

* Zookeeper Ensemble
* Hadoop HDFS and Map Reduce Cluster
* Kafka cluster
* Druid ingestion

We will build a network of Virtualbox VMs with Vagrant and Ansible, to imitate bare metal infrastructure.

Default hosts created for the lab:
* core1.lan - bind9 DNS server
* hadoop[0-2].lan - Hadoop cluster
* zookeeper[0:2].lan - Zookeeper ensemble
* kafka[0:2].lan - Kafka cluster
* druid0.lan - Druid.io Database for data ingestion

Zookeeper
=========

To test who is the Quorum leader...this should not return standalone, if it does you must restart each node quickly:
```
echo srvr | nc zookeeper0.lan 2181 | grep Mode
```

Also you can run to find out if the node is running smoothly:
```
echo ruok | nc zookeeper0.lan 2181
```

Hadoop
======

###IMPORTANT
Host resolution in Hadoop clustering is critical. This repo uses a bind9 server to resolve hostnames, forward and reverse records. While writing to the /etc/hosts file is a simple solution, this probably gets messy. I have a hybrid solution here.
On each host, if you only write it's own entry, and use DNS for other hostname resolution, it works. For instance:
hadoop0.lan's /etc/hosts file:
```
127.0.0.1 localhost
172.16.8.30 hadoop0.lan hadoop0
```


####Additional note: I fought missing jars getting the following ```hdfs namenode -format``` command to work
```
cp /opt/hadoop-2.7.2/share/hadoop/httpfs/tomcat/webapps/webhdfs/WEB-INF/lib/slf4j-api-1.7.10.jar /opt/hadoop-2.7.2/share/hadoop/common/lib/
cp /opt/hadoop-2.7.2/share/hadoop/httpfs/tomcat/webapps/webhdfs/WEB-INF/lib/slf4j-log4j12-1.7.10.jar /opt/hadoop-2.7.2/share/hadoop/common/lib/
cp /opt/hadoop-2.7.2/share/hadoop/httpfs/tomcat/webapps/webhdfs/WEB-INF/lib/commons-configuration-1.6.jar /opt/hadoop-2.7.2/share/hadoop/common/lib/
```
###format HDFS by changing user and running the commands (On the master namenode):
```
sudo su - hadoop
hdfs namenode -format
```

###Start Namenode:

```
/opt/hadoop-2.7.2/sbin/start-dfs.sh
```

###Start Mapreduce v2 Daemon:

```
/opt/hadoop-2.7.2/sbin/start-yarn.sh
```

####To verify daemons on each host, as the hadoop user:

This will display the different daemons running on the host where the command was issued.
```
jps
```

####To verify the cluster:

Navigate to the Name node Web UI: 
```
http://hadoop0.lan:8088/cluster/nodes
```

Additionally, navigate to Hadoop UI:
```
http://hadoop0.lan:50070
```
You should see all cluster nodes with storage capacity stats. If not, you may have a networking issue/DNS resolution issue.

Troubleshoot this by checking connection availability with the telnet and netstat tool.
Netstat will show you interface/process bindings. All of these should be bound to 0.0.0.0 or all interfaces
Additionally, ipv6 should be disabled
```
netstat -ntple

Proto Recv-Q Send-Q Local Address           Foreign Address         State       User       Inode       PID/Program name
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      0          7784        -               
tcp        0      0 0.0.0.0:8050            0.0.0.0:*               LISTEN      999        47462       19258/java      
tcp        0      0 0.0.0.0:50070           0.0.0.0:*               LISTEN      999        45671       18871/java      
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      0          28282       -               
tcp        0      0 0.0.0.0:8088            0.0.0.0:*               LISTEN      999        47466       19258/java      
tcp        0      0 0.0.0.0:8025            0.0.0.0:*               LISTEN      999        47448       19258/java      
tcp        0      0 0.0.0.0:8033            0.0.0.0:*               LISTEN      999        47472       19258/java      
tcp        0      0 0.0.0.0:8035            0.0.0.0:*               LISTEN      999        47456       19258/java      
tcp        0      0 0.0.0.0:32901           0.0.0.0:*               LISTEN      107        7854        -               
tcp        0      0 0.0.0.0:9000            0.0.0.0:*               LISTEN      999        45679       18871/java      
tcp        0      0 0.0.0.0:50090           0.0.0.0:*               LISTEN      999        46676       19108/java      
tcp6       0      0 :::111                  :::*                    LISTEN      0          7787        -               
tcp6       0      0 :::22                   :::*                    LISTEN      0          28284       -               
tcp6       0      0 :::34334                :::*                    LISTEN      107        7860        -  

```

Begin trying to connect to services:
```
telnet <server> <port>
telnet hadoop0.lan 9000
```

If you get connection refused errors, check the processes and logs. Below is an example of the namenode log:
```
cat /opt/hadoop-2.7.2/logs/hadoop-hadoop-namenode-hadoop0.lan.log
```

###Test by running jobs:

####Use Map Reduce v2:
```
hadoop jar /opt/hadoop-2.7.2/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.2.jar pi 30 100
```

####Use YARN:
```
yarn jar /opt/hadoop-2.7.2/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.2.jar pi 30 100
```

####Verify the mapreduce job:

http://hadoop0.lan:8088/cluster/apps

##Druid

Create a hdfs directory for druid deep storage:
===============================================

```
hdfs dfs -mkdir /user
hdfs dfs -mkdir /user/druid
hdfs dfs -mkdir /user/druid/segments
hdfs dfs -chmod 0777 /user/druid
hdfs dfs -chmod 0777 /user/druid/segments
```
------------------------------------------------

Druid
=====

Starting a coordinator node as druid (See below for upstart scripts):

```
java -Xmx256m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -classpath config/_common:config/coordinator:lib/* io.druid.cli.Main server coordinator
```

Had to append hadoop jars to the classpath (got the classes by: executing $ hadoop classpath and appending):
```
java -Xmx256m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -classpath config/_common:config/coordinator:lib/*:/opt/hadoop-2.7.2/etc/hadoop:/opt/hadoop-2.7.2/share/hadoop/common/lib/*:/opt/hadoop-2.7.2/share/hadoop/common/*:/opt/hadoop-2.7.2/share/hadoop/hdfs:/opt/hadoop-2.7.2/share/hadoop/hdfs/lib/*:/opt/hadoop-2.7.2/share/hadoop/hdfs/*:/opt/hadoop-2.7.2/share/hadoop/yarn/lib/*:/opt/hadoop-2.7.2/share/hadoop/yarn/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/lib/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/*:/contrib/capacity-scheduler/*.jar io.druid.cli.Main server coordinator
```

Starting a historical node as druid:

```
java -Xmx256m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -classpath config/_common:config/historical:lib/* io.druid.cli.Main server historical
```

Had to append hadoop jars to the classpath (got the classes by: executing $ hadoop classpath and appending):
```
java -Xmx256m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -classpath config/_common:config/historical:lib/*:/opt/hadoop-2.7.2/etc/hadoop:/opt/hadoop-2.7.2/share/hadoop/common/lib/*:/opt/hadoop-2.7.2/share/hadoop/common/*:/opt/hadoop-2.7.2/share/hadoop/hdfs:/opt/hadoop-2.7.2/share/hadoop/hdfs/lib/*:/opt/hadoop-2.7.2/share/hadoop/hdfs/*:/opt/hadoop-2.7.2/share/hadoop/yarn/lib/*:/opt/hadoop-2.7.2/share/hadoop/yarn/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/lib/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/*:/contrib/capacity-scheduler/*.jar io.druid.cli.Main server historical
```

Starting a broker node as druid:

```
java -Xmx256m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -classpath config/_common:config/broker:lib/* io.druid.cli.Main server broker
```

Had to append hadoop jars to the classpath (got the classes by: executing $ hadoop classpath and appending):
```
java -Xmx256m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -classpath config/_common:config/broker:lib/*:/opt/hadoop-2.7.2/etc/hadoop:/opt/hadoop-2.7.2/share/hadoop/common/lib/*:/opt/hadoop-2.7.2/share/hadoop/common/*:/opt/hadoop-2.7.2/share/hadoop/hdfs:/opt/hadoop-2.7.2/share/hadoop/hdfs/lib/*:/opt/hadoop-2.7.2/share/hadoop/hdfs/*:/opt/hadoop-2.7.2/share/hadoop/yarn/lib/*:/opt/hadoop-2.7.2/share/hadoop/yarn/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/lib/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/*:/contrib/capacity-scheduler/*.jar io.druid.cli.Main server broker
```

Starting realtime node as druid:
```
java -Xmx512m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Ddruid.realtime.specFile=examples/wikipedia/wikipedia_realtime.spec -classpath config/_common:config/realtime:lib/* io.druid.cli.Main server realtime
```

Had to append hadoop jars to the classpath (got the classes by: executing $ hadoop classpath and appending):
```
java -Xmx512m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Ddruid.realtime.specFile=examples/wikipedia/wikipedia_realtime.spec -classpath config/_common:config/realtime:lib/*:/opt/hadoop-2.7.2/etc/hadoop:/opt/hadoop-2.7.2/share/hadoop/common/lib/*:/opt/hadoop-2.7.2/share/hadoop/common/*:/opt/hadoop-2.7.2/share/hadoop/hdfs:/opt/hadoop-2.7.2/share/hadoop/hdfs/lib/*:/opt/hadoop-2.7.2/share/hadoop/hdfs/*:/opt/hadoop-2.7.2/share/hadoop/yarn/lib/*:/opt/hadoop-2.7.2/share/hadoop/yarn/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/lib/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/*:/contrib/capacity-scheduler/*.jar io.druid.cli.Main server realtime
```

Upstart Files:
==============

* ```start|stop|restart druid-coordinator```
* ```start|stop|restart druid-historical```
* ```start|stop|restart druid-broker```
* ```start|stop|restart druid-middlemanager```
* ```start|stop|restart druid-overlord```

runtime logs at /var/log/upstart/*


Cluster Batch Data Loading
==========================

(Druid Documentation)[http://druid.io/docs/latest/tutorials/tutorial-loading-batch-data.html]

In my experience to get around the capacity errors, you need 2 historical nodes.
```
start druid-overlord
start druid-coordinator 
start druid-historical
start druid-broker
start druid-middlemanager
```

One by one, check for errors as the servers start up:
```
tail -n 1000 -f /var/log/upstart/druid-overlord.log
tail -n 1000 -f /var/log/upstart/druid-coordinator.log
tail -n 1000 -f /var/log/upstart/druid-historical.log
tail -n 1000 -f /var/log/upstart/druid-broker.log
tail -n 1000 -f /var/log/upstart/druid-middlemanager.log
```
###Tranquility Server
The tranquility role installs a server to communicate with druid in realtime
```
start tranquility
```

###Generate metrics Task:
```
/opt/druid-0.9.1.1/bin/generate-example-metrics | curl -XPOST -H'Content-Type: application/json' --data-binary @- http://druid0.lan:8200/v1/post/metrics
```

Coordinator console:
http://druid0.lan:8090/console.html

Druid Console:
http://druid0.lan:8081

HDFS Segment:
/user/druid/segments/wikipedia/20130831T000000.000Z_20130901T000000.000Z/2016-01-17T03_23_16.720Z/0

###Additional Queries

To query for ALL data (across realtime and historical nodes) issue the query to the broker node:

```
curl -X POST 'http://localhost:8082/druid/v2/?pretty' -H 'content-type: application/json' -d@examples/wikipedia/query.body
```


Kafka
=====

may have to update /var/log/kafka/meta.properties is the broker id has changed

Create a topic for ingestion:
```
./bin/kafka-topics.sh --create --zookeeper zookeeper0.lan:2181,zookeeper1.lan:2181,zookeeper2.lan:2181 --replication-factor 3 --partitions 1 --topic pageviews
```

Check the replication and partition:
```
bin/kafka-topics.sh --describe --zookeeper zookeeper0.lan:2181,zookeeper1.lan:2181,zookeeper2.lan:2181 --topic pageviews
```

Create a producer:
```
./bin/kafka-console-producer.sh --broker-list kafka0.lan:9092,kafka1.lan:9092,kafka2.lan:9092 --topic pageviews
```

###Tranquility Kafka Consumer
root@druid0:/opt/druid-0.9.1.1/bin# cat /opt/druid-0.9.1.1/conf-quickstart/tranquility/kafka.json 
```
{
  "dataSources" : {
    "pageviews-kafka" : {
      "spec" : {
        "dataSchema" : {
          "dataSource" : "pageviews-kafka",
          "parser" : {
            "type" : "string",
            "parseSpec" : {
              "timestampSpec" : {
                "column" : "time",
                "format" : "auto"
              },
              "dimensionsSpec" : {
                "dimensions" : ["url","user"]
              },
              "format" : "json"
            }
          },
          "granularitySpec" : {
            "type" : "uniform",
            "segmentGranularity" : "minute",
            "queryGranularity" : "none"
          },
          "metricsSpec" : [
            {
              "type" : "count",
              "name" : "views"
            },
            {
              "name" : "latencyMs",
              "type" : "doubleSum",
              "fieldName" : "latencyMs"
            }
          ]
        },
        "ioConfig" : {
          "type" : "realtime"
        },
        "tuningConfig" : {
          "type" : "realtime",
          "maxRowsInMemory" : "100000",
          "intermediatePersistPeriod" : "PT10M",
          "windowPeriod" : "PT10M"
        }
      },
      "properties" : {
        "task.partitions" : "1",
        "task.replicants" : "1",
        "topicPattern" : "pageviews"
      }
    }
  },
  "properties" : {
    "zookeeper.connect" : "zookeeper0.lan:2181,zookeeper1.lan:2181,zookeeper2.lan:2181",
    "druid.discovery.curator.path" : "/druid/discovery",
    "druid.selectors.indexing.serviceName" : "druid/overlord",
    "commit.periodMillis" : "15000",
    "consumer.numThreads" : "2",
    "kafka.zookeeper.connect" : "zookeeper0.lan:2181,zookeeper1.lan:2181,zookeeper2.lan:2181",
    "kafka.group.id" : "tranquility-kafka"
  }
}
```
###Metabase UI
```
java -jar metabase.jar
```

Browse to:
```
http://druid0.lan:3000
```

###Generating Metrics
root@druid0:/opt/druid-0.9.1.1/bin# cat genmetrics 
```
#!/usr/bin/env python

import argparse
import json
import random
import sys
from datetime import datetime

def main():
  parser = argparse.ArgumentParser(description='Generate example page request latency metrics.')
  parser.add_argument('--count', '-c', type=int, default=25, help='Number of events to generate (negative for unlimited)')
  args = parser.parse_args()

  count = 0
  while args.count < 0 or count < args.count:
    timestamp = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

    r = random.randint(1, 4)
    if r == 1 or r == 2:
      user = 'bill'
    elif r == 3:
      user = 'tom'
    else:
      user = 'user' + str(random.randint(1, 99))

    u = random.randint(1, 4)
    if u == 1 or u == 2:
      url = '/'
    elif u == 3:
      url = '/login'
    else:
      url = '/page' + str(random.randint(1, 99))

    views = random.randint(1, 200)

    latencyMs = random.randint(80, 400)

    print(json.dumps({
      'time': timestamp,
      'latencyMs': int(latencyMs),
      'url': url,
      'views': int(views)
    }))

    count += 1

try:
  main()
except KeyboardInterrupt:
  sys.exit(1)
```

Paste output into the Kafka Producer
