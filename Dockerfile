# Verwende ein Basis-Image mit Java
FROM openjdk:17-jdk-slim

LABEL name="Stakater Maven Image on CentOS" \    
      maintainer="Stakater <stakater@aurorasolutions.io>" \
      vendor="Stakater" \
      release="1" \
      summary="A Maven based image on CentOS" 

# Setting Maven Version that needs to be installed
ARG MAVEN_VERSION=3.6.0

RUN /bin/sh -c set -eux; apt-get update; apt-get install -y curl

#------------------- part 1 compile java mit maven ------------------
# Maven
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_VERSION=${MAVEN_VERSION}
ENV M2_HOME /usr/share/maven
ENV maven.home $M2_HOME
ENV M2 $M2_HOME/bin
ENV PATH $M2:$PATH
COPY src /usr/src/app/src  
COPY pom.xml /usr/src/app 
# COPY web.xml /usr/src/app
RUN mvn -f /usr/src/app/pom.xml clean package 

RUN ls /usr/src/app/
RUN ls /usr/src/app/target/

#------------------- part 2 Tomcat ------------------
# Erstelle ein Verzeichnis für Tomcat
# Definiere die Tomcat-Version
ENV TOMCAT_VERSION 10.1.40
RUN mkdir /opt/tomcat

# Lade und entpacke Tomcat
RUN curl -fsSL https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz | \
    tar -xz -C /opt/tomcat --strip-components=1

# Setze Umgebungsvariablen
ENV CATALINA_HOME /opt/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN rm -rf $CATALINA_HOME/webapps/ROOT
RUN cp /usr/src/app/target/*.war $CATALINA_HOME/webapps/
RUN cd $CATALINA_HOME/webapps/ && jar -xvf $CATALINA_HOME/webapps/*.war
RUN mkdir $CATALINA_HOME/webapps/ROOT
RUN cp -rf $CATALINA_HOME/webapps/manager/* $CATALINA_HOME/webapps/ROOT/
RUN ls -la $CATALINA_HOME/webapps/ROOT/
RUN cd $CATALINA_HOME/bin && chmod +x *.sh

# Exponiere Port 8080
EXPOSE 8080

# Start-Skript
CMD ["catalina.sh", "run"]