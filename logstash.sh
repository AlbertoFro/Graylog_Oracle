#!/bin/sh
# Init script for logstash
# Maintained by Elasticsearch
# Generated by pleaserun.
# Implemented based on LSB Core 3.1:
#   * Sections: 20.2, 20.3
#
### BEGIN INIT INFO
# Provides:          logstash
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: 
# Description:        Starts Logstash as a daemon.
### END INIT INFO

PATH=/sbin:/usr/sbin:/bin:/usr/bin
export PATH

if [ `id -u` -ne 0 ]; then
   echo "You need root privileges to run this script"
   exit 1
fi

name=logstash
pidfile="/var/run/$name.pid"

LS_USER=logstash
LS_GROUP=logstash
LS_HOME=/var/lib/logstash
LS_HEAP_SIZE="500m"
LS_LOG_DIR=/var/log/logstash
LS_LOG_FILE="${LS_LOG_DIR}/$name.log"
LS_CONF_DIR=/etc/logstash/conf.d
LS_OPEN_FILES=16384
LS_NICE=19
LS_OPTS=""


[ -r /etc/default/$name ] && . /etc/default/$name
[ -r /etc/sysconfig/$name ] && . /etc/sysconfig/$name

program=/opt/logstash/bin/logstash
args="agent -f ${LS_CONF_DIR} -l ${LS_LOG_FILE} ${LS_OPTS}"

start() {

  LS_JAVA_OPTS="${LS_JAVA_OPTS} -Djava.io.tmpdir=${LS_HOME}"
  HOME=${LS_HOME}
  export PATH HOME LS_HEAP_SIZE LS_JAVA_OPTS LS_USE_GC_LOGGING

  # set ulimit as (root, presumably) first, before we drop privileges
  ulimit -n ${LS_OPEN_FILES}

  # Run the program!
  nice -n ${LS_NICE} chroot --userspec $LS_USER:$LS_GROUP / sh -c "
    cd $LS_HOME
    ulimit -n ${LS_OPEN_FILES}
    exec \"$program\" $args
  " > /dev/null &
  # > "${LS_LOG_DIR}/$name.stdout" 2> "${LS_LOG_DIR}/$name.err" &

  # Generate the pidfile from here. If we instead made the forked process
  # generate it there will be a race condition between the pidfile writing
  # and a process possibly asking for status.
  echo $! > $pidfile

  echo "$name started."
  return 0
}
