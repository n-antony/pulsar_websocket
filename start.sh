#!/bin/bash
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

# Ensure Pulsar is downloaded
if [ ! -d "apache-pulsar-4.0.3" ]; then
    curl -LO "https://www.apache.org/dyn/closer.lua/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz?action=download"
    tar xvfz apache-pulsar-4.0.3-bin.tar.gz
fi

# Copy custom Pulsar configuration
cp /app/pulsar-config/standalone.conf apache-pulsar-4.0.3/conf/standalone.conf

# Start Pulsar in the background
cd apache-pulsar-4.0.3
bin/pulsar standalone &

# Wait for Pulsar to initialize (adjust as needed)
sleep 10

# Start the Python producer in the background
cd /app
python3 producer.py &

# Keep the container running
wait
