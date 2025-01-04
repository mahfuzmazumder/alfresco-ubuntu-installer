#!/bin/bash

set -e

echo "Install unzip command"
sudo apt -y install unzip

echo "Create support folders and configuration in Tomcat"
mkdir -p /home/tomcat/shared/classes && mkdir -p /home/tomcat/shared/lib
sed -i 's|^shared.loader=$|shared.loader=${catalina.base}/shared/classes,${catalina.base}/shared/lib/*.jar|' /home/tomcat/conf/catalina.properties

echo "Unzip Alfresco ZIP Distribution File"
mkdir /tmp/alfresco
unzip downloads/alfresco-content-services-community-distribution-23.2.1.zip -d /tmp/alfresco

echo "Copy JDBC driver"
cp /tmp/alfresco/web-server/lib/postgresql-42.6.0.jar /home/tomcat/shared/lib/

echo "Configure JAR Addons deployment"
mkdir -p /home/modules/platform && mkdir -p /home/modules/share && mkdir -p /home/tomcat/conf/Catalina/localhost
cp /tmp/alfresco/web-server/conf/Catalina/localhost/* /home/tomcat/conf/Catalina/localhost/

echo "Install Web Applications"
cp /tmp/alfresco/web-server/webapps/* /home/tomcat/webapps/

echo "Apply configuration"
cp -r /tmp/alfresco/web-server/shared/classes/* /home/tomcat/shared/classes/
mkdir /home/keystore && cp -r /tmp/alfresco/keystore/* /home/keystore/
mkdir /home/alf_data
cat <<EOL | tee /home/tomcat/shared/classes/alfresco-global.properties
#
# Custom content and index data location
#
dir.root=/home/alf_data
dir.keystore=/home/keystore/

#
# Database connection properties
#
db.username=alfresco
db.password=alfresco
db.driver=org.postgresql.Driver
db.url=jdbc:postgresql://localhost:5432/alfresco

#
# Solr Configuration
#
solr.secureComms=secret
solr.sharedSecret=secret
solr.host=localhost
solr.port=8983
index.subsystem.name=solr6

# 
# Transform Configuration
#
localTransform.core-aio.url=http://localhost:8090/

#
# Events Configuration
#
messaging.broker.url=failover:(nio://localhost:61616)?timeout=3000&jms.useCompression=true

#
# URL Generation Parameters
#-------------
alfresco.context=alfresco
alfresco.host=localhost
alfresco.port=8080
alfresco.protocol=http
share.context=share
share.host=localhost
share.port=8080
share.protocol=http
EOL

echo "Apply AMPs"
mkdir /home/amps && cp -r /tmp/alfresco/amps/* /home/amps/
mkdir /home/bin && cp -r /tmp/alfresco/bin/* /home/bin/
java -jar /home/bin/alfresco-mmt.jar install /home/amps /home/tomcat/webapps/alfresco.war -directory
java -jar /home/bin/alfresco-mmt.jar list /home/tomcat/webapps/alfresco.war

echo "Modify alfresco and share logs directory"
mkdir /home/tomcat/webapps/alfresco && unzip /home/tomcat/webapps/alfresco.war -d /home/tomcat/webapps/alfresco
mkdir /home/tomcat/webapps/share && unzip /home/tomcat/webapps/share.war -d /home/tomcat/webapps/share
sed -i 's|^appender\.rolling\.fileName=alfresco\.log|appender.rolling.fileName=/home/tomcat/logs/alfresco.log|' /home/tomcat/webapps/alfresco/WEB-INF/classes/log4j2.properties
sed -i 's|^appender\.rolling\.fileName=share\.log|appender.rolling.fileName=/home/tomcat/logs/share.log|' /home/tomcat/webapps/share/WEB-INF/classes/log4j2.properties


echo "Alfresco has been configured"