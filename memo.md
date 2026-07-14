# 起動
EAP_HOME=/Users/kamori/jboss/jboss-eap-7.4
$EAP_HOME/bin/standalone.sh --server-config=standalone-full.xml

# 管理CLI起動
EAP_HOME=/Users/kamori/jboss/jboss-eap-7.4
$EAP_HOME/bin/jboss-cli.sh --connect

# 管理CLI からtopicの追加とJDBCドライバのインストールを行います。

jms-topic add --topic-address=orders --entries=[/topic/orders]

module add --name=org.postgres --resources=/Users/kamori/jboss/postgresql-42.7.3.jar --dependencies=javax.api,javax.transaction.api
/subsystem=datasources/jdbc-driver=postgres:add(driver-module-name=org.postgres, driver-name=postgres)

data-source add --name=postgresDS --jndi-name=java:jboss/datasources/CoolstoreDS \
--driver-name=postgres \
--connection-url=jdbc:postgresql://localhost:5432/postgres \
--user-name=postgres --password=postgres

data-source add --name=postgresDS --jndi-name=java:jboss/datasources/CoolstoreDS --driver-name=postgres --connection-url=jdbc:postgresql://localhost:5432/postgres --user-name=postgres --password=postgres