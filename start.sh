#!/bin/bash

# Set Java Home
export JAVA_HOME=/opt/render/.parts/opt/openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Move to project directory
cd /opt/render/project/src

# Copy custom config
mkdir -p apache-pulsar-4.0.3/conf/
cp pulsar-config/standalone.conf apache-pulsar-4.0.3/conf/

# Start Pulsar in standalone mode with custom config
apache-pulsar-4.0.3/bin/pulsar standalone -c apache-pulsar-4.0.3/conf/standalone.conf &
sleep 10

# Start Pulsar Producer
python3 pulsar-producer/pulsar-producer.py
