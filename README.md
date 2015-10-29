# Graylog_Oracle

#General Prerequisites

•	Graylog installation

•	Oracle Installation

#Installation/Setting
    

1.	Create SASHNOW View

2.	download/install logstash with root (user or privilegies) (tested on logstash-1.4.2)  https://www.elastic.co/downloads/past-releases/logstash-1-4-2-2?q=logstash-1.4.2

3.	Or download my archive logstash.tar here https://www.dropbox.com/s/qmem5ph7i4tn9gx/logstash.tar?dl=0 (orasql.rb lib it's included) for further details http://krisrice.blogspot.it/2015/05/logstash-and-oracle-database.html

4.  Create orasql.rb file

5.	Create logstash.conf and set your ip_address_graylog_server in the appropriate section.

6.	Create  logstash service on linux enviroment (service logstash start/stop) logstash file /etc/init.d

7.	Download and install Oracle content Pack Dashboard.json in Graylog

8.	Check SQL message in graylog server
