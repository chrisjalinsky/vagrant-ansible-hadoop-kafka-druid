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
* ```start|stop|restart druid-realtime```
* ```start|stop|restart druid-kafka-realtime```
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
```

One by one, check for errors as the servers start up:
```
tail -n 1000 -f /var/log/upstart/druid-overlord.log
tail -n 1000 -f /var/log/upstart/druid-coordinator.log
tail -n 1000 -f /var/log/upstart/druid-historical.log
tail -n 1000 -f /var/log/upstart/druid-broker.log
```

Task:
=====
```
curl -X 'POST' -H 'Content-Type:application/json' -d @examples/indexing/wikipedia_index_task.json <overlord>:8090/druid/indexer/v1/task
curl -X 'POST' -H 'Content-Type:application/json' -d @examples/indexing/wikipedia_index_task.json druid0.lan:8090/druid/indexer/v1/task
```

Coordinator console:
http://druid0.lan:8090/console.html

Druid Console:
http://druid0.lan:8081

HDFS Segment:
/user/druid/segments/wikipedia/20130831T000000.000Z_20130901T000000.000Z/2016-01-17T03_23_16.720Z/0

Additional Queries
==================

To query for ALL data (across realtime and historical nodes) issue the query to the broker node:

```
curl -X POST 'http://localhost:8082/druid/v2/?pretty' -H 'content-type: application/json' -d@examples/wikipedia/query.body
```


Kafka
=====

may have to update /var/log/kafka/meta.properties is the broker id has changed

Create a topic for ingestion:
```
./bin/kafka-topics.sh --create --zookeeper cd1.lan:2181 --replication-factor 3 --partitions 1 --topic wikipedia
```

Check the replication and partition:
```
bin/kafka-topics.sh --describe --zookeeper cd1.lan:2181 --topic wikipedia
```

Create a producer:
```
./bin/kafka-console-producer.sh --broker-list cd1.lan:9092 --topic wikipedia
```

Start realtime with the kafka wikipedia spec:
```
java -Xmx512m -Duser.timezone=UTC -Dfile.encoding=UTF-8         \
     -Ddruid.realtime.specFile=examples/indexing/wikipedia.spec \
     -classpath "config/_common:config/realtime:lib/*"          \
     io.druid.cli.Main server realtime
```

Had to append hadoop jars to the classpath (got the classes by: executing $ hadoop classpath and appending):

```
java -Xmx512m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Ddruid.realtime.specFile=examples/indexing/wikipedia.spec -classpath "config/_common:config/realtime:lib/*:/opt/hadoop-2.7.2/etc/hadoop:/opt/hadoop-2.7.2/share/hadoop/common/lib/*:/opt/hadoop-2.7.2/share/hadoop/common/*:/opt/hadoop-2.7.2/share/hadoop/hdfs:/opt/hadoop-2.7.2/share/hadoop/hdfs/lib/*:/opt/hadoop-2.7.2/share/hadoop/hdfs/*:/opt/hadoop-2.7.2/share/hadoop/yarn/lib/*:/opt/hadoop-2.7.2/share/hadoop/yarn/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/lib/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/*:/contrib/capacity-scheduler/*.jar" io.druid.cli.Main server realtime
```

Paste the ingestion into Kafka producer:

```
{"timestamp": "2016-01-11T00:30:00.000Z", "page": "Gypsy Danger 4", "language" : "en", "user" : "nuclear", "unpatrolled" : "true", "newPage" : "true", "robot": "false", "anonymous": "false", "namespace":"article", "continent":"North America", "country":"United States", "region":"Bay Area", "city":"San Francisco", "added": 57, "deleted": 200, "delta": -143}
{"timestamp": "2016-01-11T00:30:01.000Z", "page": "Striker Eureka 4", "language" : "en", "user" : "speed", "unpatrolled" : "false", "newPage" : "true", "robot": "true", "anonymous": "false", "namespace":"wikipedia", "continent":"Australia", "country":"Australia", "region":"Cantebury", "city":"Syndey", "added": 459, "deleted": 129, "delta": 330}
{"timestamp": "2016-01-11T00:30:02.000Z", "page": "Cherno Alpha 4", "language" : "ru", "user" : "masterYi", "unpatrolled" : "false", "newPage" : "true", "robot": "true", "anonymous": "false", "namespace":"article", "continent":"Asia", "country":"Russia", "region":"Oblast", "city":"Moscow", "added": 123, "deleted": 12, "delta": 111}
{"timestamp": "2016-01-11T00:30:03.000Z", "page": "Crimson Typhoon 4", "language" : "zh", "user" : "triplets", "unpatrolled" : "true", "newPage" : "false", "robot": "true", "anonymous": "false", "namespace":"wikipedia", "continent":"Asia", "country":"China", "region":"Shanxi", "city":"Taiyuan", "added": 905, "deleted": 5, "delta": 900}
{"timestamp": "2016-01-11T00:30:04.000Z", "page": "Coyote Tango 4", "language" : "ja", "user" : "stringer", "unpatrolled" : "true", "newPage" : "false", "robot": "true", "anonymous": "false", "namespace":"wikipedia", "continent":"Asia", "country":"Japan", "region":"Kanto", "city":"Tokyo", "added": 1, "deleted": 10, "delta": -9}
```

Query the data:
```
curl -XPOST -H'Content-type: application/json' \
  "http://cd1.lan:8084/druid/v2/?pretty" \
  -d'{"queryType":"timeBoundary","dataSource":"wikipedia"}'
```
