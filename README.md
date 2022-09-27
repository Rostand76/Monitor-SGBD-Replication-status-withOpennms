# Monitor-SGBD-Replication-status-with-Opennms
Monitor SGBD replication status with OpenNNMS
I had this idea to supervise the replication status of my various SGBD in order to be able to quickly intervene in case of problems. Dan this article I did it only our **mariadb mysql** and **postgreql**

**1. Mariadb**
   Add in Pollerd  poller-configuration.xml
    
```
**<service name="Mariadb-Replication-Service" interval="30000" user-defined="true" status="on">**
**     <parameter key="driver" value="org.mariadb.jdbc.Driver"/>**
**     <parameter key="url" value="jdbc:mysql://OPENNMS_JDBC_HOSTNAME:3306/information_schema"/>**
**     <parameter key="user" value="my_user"/>**
**     <parameter key="password" value="my_password"/>**
**     <parameter key="query" value="SELECT variable_value FROM information_schema.global_status WHERE variable_name='SLAVE_RUNNING'"/>**
**     <parameter key="column" value="state"/>**
**     <parameter key="action" value="compare_string"/>**
**     <parameter key="operator" value="!="/>**
**     <parameter key="operand" value="ON"/>**
**     <parameter key="message" value="Replication service not running"/>**
**  </service>**
<monitor service="Mariadb-Replication-Service" class-name="org.opennms.netmgt.poller.monitors.JDBCQueryMonitor"/>
```
To enable the services, you have to restart OpenNMS. When OpenNMS is restarted assign the service *Mariadb-Replication-Service* to an SNMP enabled IP interface of your Node in OpenNMS.


**2. mysql**
    Add in Pollerd  poller-configuration.xml

```
<service name="MySQL-Replication-Service" interval="30000" user-defined="true" status="on">
     <parameter key="driver" value="com.mysql.jdbc.Driver"/>
     <parameter key="url" value="jdbc:mysql://OPENNMS_JDBC_HOSTNAME:3306/performance_schema?useSSL=false"/>
     <parameter key="user" value="my_user"/>
     <parameter key="password" value="my_password"/>
     <parameter key="query" value="SELECT SERVICE_STATE FROM performance_schema.replication_connection_status"/>
     <parameter key="column" value="SERVICE_STATE"/>
     <parameter key="action" value="compare_string"/>
     <parameter key="operator" value="!="/>
     <parameter key="operand" value="ON"/>
     <parameter key="message" value="Replication service not running"/>
  </service>
<monitor service="MySQL-Replication-Service" class-name="org.opennms.netmgt.poller.monitors.JDBCQueryMonitor"/>
```
To enable the services, you have to restart OpenNMS. When OpenNMS is restarted assign the service *MySQL-Replication-Service* to an SNMP enabled IP interface of your Node in OpenNMS.


  **3. PostgreSQL**
in this particular case, it was difficult for me to recover the valeu streaming in the master database. So I created a bash script that takes care of going to recover it e later I added to the file /etc/smp/snmpd.conf.

> #!/bin/bash
> 
> check=$(su -c "psql -d postgres -c \"SELECT state FROM pg_stat_replication where state='streaming'\"" postgres | grep streaming)
> 
> if [ "$check" = "" ]; then
> 	echo "1"
> else
> 	echo "0"
> fi

 Extend the Net-SNMP agent to run the scripts in /etc/snmpd.conf with
`extend smart_health /bin/bash -c 'sudo /usr/local/bin/postgres.sh'`

after you restart restart snmp
`systemctl restart snmpd`

Test if you can request the OID from your monitoring server with:
`snmpwalk -One -v2c -c <your-community> <your-server> .1.3.6.1.4.1.8072.1.3.2.4.1.2.12.115.109.97.114.116.95.104.101.97.108.116.104.1`

Add SNMP monitors in Pollerd to test extended scripts in poller-configuration.xml
Create a SNMP monitor in Pollerd with the following configuration parameters:

```
<service name="PostgreSQl-Replication-Health" interval="43200000" user-defined="true" status="on">
    <parameter key="oid" value=".1.3.6.1.4.1.8072.1.3.2.4.1.2.12.115.109.97.114.116.95.104.101.97.108.116.104.1"/>
    <parameter key="retry" value="1"/>
    <parameter key="timeout" value="3000"/>
    <parameter key="port" value="161"/>
    <parameter key="operator" value="="/>
    <parameter key="operand" value="0"/>
</service>

<monitor service="PostgreSQl-Replication-Health" class-name="org.opennms.netmgt.poller.monitors.SnmpMonitor"/>
```

To enable the services, you have to restart OpenNMS. When OpenNMS is restarted assign the service *PostgreSQl-Replication-Health* to an SNMP enabled IP interface of your Node in OpenNMS or use an SNMP detector for the given OIDS.
