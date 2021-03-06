#!/bin/bash
#
# Copyright 2015 Red Hat, Inc. and/or its affiliates
# and other contributors as indicated by the @author tags.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
if [ "${TEST_MODE}" == "true" ]; then
    echo " ## Test mode detected ##"
    CONFIG_DIR=${HAWKULAR_HOME}/standalone/configuration
    cp -b $CONFIG_DIR/hawkular-realm-for-dev.json $CONFIG_DIR/hawkular-realm.json 
    
    # Enable monitoring agent
    xsltproc --output $CONFIG_DIR/standalone-tmp.xml \
             --stringparam username jdoe --stringparam password password \
             ${JBOSS_BASE}/agent.xsl $CONFIG_DIR/standalone.xml  
    cp -b $CONFIG_DIR/standalone-tmp.xml $CONFIG_DIR/standalone.xml
fi

if [ !  -z "${CASSANDRA_NODES}" ]; then
   echo " ## Using external storage nodes ##"
   export HAWKULAR_BACKEND=cassandra
elif [ ! -z "${CASSANDRA_SERVICE}" ]; then
   echo " ## Using Kubernetes-style named service"
   export HAWKULAR_BACKEND=cassandra
   eval "s=${CASSANDRA_SERVICE}_SERVICE_HOST"
   export CASSANDRA_NODES=${!s}
   echo ${CASSANDRA_NODES}
fi

if [ -z "${HAWKULAR_URL}" ]; then
    export HAWKULAR_URL="localhost:8080"
fi

echo " ## Setting Hawkular URL to ${HAWKULAR_URL} ##"

${HAWKULAR_HOME}/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0 \
  -Dkeycloak.server.url=http://${HAWKULAR_URL}/auth \
  -Djboss.server.data.dir=/data \
  -Dhawkular-alerts.cassandra-retry-attempts=10 \
  -Dhawkular-alerts.cassandra-retry-timeout=3000 \
  -Djboss.as.management.blocking.timeout=480

exit $?
