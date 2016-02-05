Zookeeper
=========

To test who is the Quorum leader...this should not return standalone, if it does you must restart each node quickly:
```
echo srvr | nc cd1.lan 2181 | grep Mode
```

Also you can run to find out if the node is running smoothly:
```
echo ruok | nc cd3.lan 2181
```

Hadoop
======

format HDFS by changing user and running the commands (On the master namenode):
```
sudo su - hadoop
hdfs namenode -format
```

Start Namenode:

```
/opt/hadoop-2.7.2/sbin/start-dfs.sh
```

Start Mapreduce v2 Daemon:
==========================

```
/opt/hadoop-2.7.2/sbin/start-yarn.sh
```

To verify daemons on each host, as the hadoop user:
===================================================

```
jps
```

To verify the cluster:
======================

Navigate to the masternode: http://cd1.lan:8088/cluster/nodes

Run a mapreduce job:
=====================

hadoop jar /opt/hadoop-2.7.2/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.2.jar pi 30 100
yarn jar /opt/hadoop-2.7.2/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.2.jar pi 30 100

Verify the mapreduce job:
=========================

http://cd1.lan:8088/cluster/apps


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

On cd2.lan, had to append hadoop jars to the classpath (got the classes by: executing $ hadoop classpath and appending):
```
java -Xmx256m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -classpath config/_common:config/coordinator:lib/*:/opt/hadoop-2.7.2/etc/hadoop:/opt/hadoop-2.7.2/share/hadoop/common/lib/*:/opt/hadoop-2.7.2/share/hadoop/common/*:/opt/hadoop-2.7.2/share/hadoop/hdfs:/opt/hadoop-2.7.2/share/hadoop/hdfs/lib/*:/opt/hadoop-2.7.2/share/hadoop/hdfs/*:/opt/hadoop-2.7.2/share/hadoop/yarn/lib/*:/opt/hadoop-2.7.2/share/hadoop/yarn/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/lib/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/*:/contrib/capacity-scheduler/*.jar io.druid.cli.Main server coordinator
```

Starting a historical node as druid:

```
java -Xmx256m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -classpath config/_common:config/historical:lib/* io.druid.cli.Main server historical
```

On cd2.lan, had to append hadoop jars to the classpath (got the classes by: executing $ hadoop classpath and appending):
```
java -Xmx256m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -classpath config/_common:config/historical:lib/*:/opt/hadoop-2.7.2/etc/hadoop:/opt/hadoop-2.7.2/share/hadoop/common/lib/*:/opt/hadoop-2.7.2/share/hadoop/common/*:/opt/hadoop-2.7.2/share/hadoop/hdfs:/opt/hadoop-2.7.2/share/hadoop/hdfs/lib/*:/opt/hadoop-2.7.2/share/hadoop/hdfs/*:/opt/hadoop-2.7.2/share/hadoop/yarn/lib/*:/opt/hadoop-2.7.2/share/hadoop/yarn/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/lib/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/*:/contrib/capacity-scheduler/*.jar io.druid.cli.Main server historical
```

Starting a broker node as druid:

```
java -Xmx256m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -classpath config/_common:config/broker:lib/* io.druid.cli.Main server broker
```
On cd2.lan, had to append hadoop jars to the classpath (got the classes by: executing $ hadoop classpath and appending):
```
java -Xmx256m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -classpath config/_common:config/broker:lib/*:/opt/hadoop-2.7.2/etc/hadoop:/opt/hadoop-2.7.2/share/hadoop/common/lib/*:/opt/hadoop-2.7.2/share/hadoop/common/*:/opt/hadoop-2.7.2/share/hadoop/hdfs:/opt/hadoop-2.7.2/share/hadoop/hdfs/lib/*:/opt/hadoop-2.7.2/share/hadoop/hdfs/*:/opt/hadoop-2.7.2/share/hadoop/yarn/lib/*:/opt/hadoop-2.7.2/share/hadoop/yarn/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/lib/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/*:/contrib/capacity-scheduler/*.jar io.druid.cli.Main server broker
```

Starting realtime node as druid:
```
java -Xmx512m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Ddruid.realtime.specFile=examples/wikipedia/wikipedia_realtime.spec -classpath config/_common:config/realtime:lib/* io.druid.cli.Main server realtime
```
On cd2.lan, had to append hadoop jars to the classpath (got the classes by: executing $ hadoop classpath and appending):
```
java -Xmx512m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Ddruid.realtime.specFile=examples/wikipedia/wikipedia_realtime.spec -classpath config/_common:config/realtime:lib/*:/opt/hadoop-2.7.2/etc/hadoop:/opt/hadoop-2.7.2/share/hadoop/common/lib/*:/opt/hadoop-2.7.2/share/hadoop/common/*:/opt/hadoop-2.7.2/share/hadoop/hdfs:/opt/hadoop-2.7.2/share/hadoop/hdfs/lib/*:/opt/hadoop-2.7.2/share/hadoop/hdfs/*:/opt/hadoop-2.7.2/share/hadoop/yarn/lib/*:/opt/hadoop-2.7.2/share/hadoop/yarn/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/lib/*:/opt/hadoop-2.7.2/share/hadoop/mapreduce/*:/contrib/capacity-scheduler/*.jar io.druid.cli.Main server realtime
```

Upstart Files:
==============

start druid-coordinator
start druid-historical
start druid-broker
start druid-realtime
start druid-kafka-realtime
start druid-overlord

runtime logs at /var/log/upstart/*


Cluster Batch Data Loading
==========================

(Druid Documentation)[http://druid.io/docs/latest/tutorials/tutorial-loading-batch-data.html]

In my experience to get around the capacity errors, you need 2 historical nodes (perhaps cd1.lan, cd2.lan).
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
curl -X 'POST' -H 'Content-Type:application/json' -d @examples/indexing/wikipedia_index_task.json cd1.lan:8090/druid/indexer/v1/task
```

Coordinator console:
http://cd1.lan:8090/console.html

Druid Console:
http://cd1.lan:8081

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

On cd2.lan, had to append hadoop jars to the classpath (got the classes by: executing $ hadoop classpath and appending):

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

Druid Dumbo Ruby Library (worth checking out)
========================

Reorganizes segments in HDFS
