DevOps Project – Technology and Service Requirements
Core Runtime Requirements
JDK: 21
Maven: 3.9.9
MySQL: 8.0.35
===============================================
Application Tech Stack
Maven (Build tool)
JSP / Servlet
Tomcat 10 (Runs on JDK 21)
MySQL 8 (Primary database)
Memcached 1.6 (Caching layer)
RabbitMQ 4.0 (Message broker)
Elasticsearch (Search engine)
Nginx (Reverse proxy / Web server)

Database Seed File:
src/main/resources/db_backup.sql
===============================================
Docker Images
The project uses four separate container images, all pushed to Docker Hub under the sansv namespace.

sansv/rmq-webapp-project
RabbitMQ message broker service.

sansv/mc-webapp-project
Memcached caching service.

sansv/db-webapp-project
MySQL 8 database service.

sansv/tomcat-webapp-project
Main Java web application running on Tomcat 10 (JDK 21).
