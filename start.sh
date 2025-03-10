#!/bin/bash

# Set environment variables
export JAVA_HOME=$PWD/jdk-17
export PATH=$JAVA_HOME/bin:$PATH

# Check if Java is already installed
if [ ! -d "$JAVA_HOME" ]; then
  echo "Downloading and extracting OpenJDK 17..."
  curl -LO https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.tar.gz
  tar -xzf jdk-17.0.12_linux-x64_bin.tar.gz
  mv jdk-17.0.12 jdk-17
fi

# Download & extract Pulsar if not already present
if [ ! -d "apache-pulsar-4.0.3" ]; then
  echo "Downloading and extracting Pulsar..."
  curl -LO "https://downloads.apache.org/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz"
  tar xvfz apache-pulsar-4.0.3-bin.tar.gz
fi

# Copy the custom Pulsar standalone.conf
cp pulsar-config/standalone.conf apache-pulsar-4.0.3/conf/standalone.conf

# Start Pulsar
echo "Starting Pulsar..."
cd apache-pulsar-4.0.3
bin/pulsar standalone &
sleep 10  # Allow Pulsar to initialize

# Start Producer
echo "Starting Pulsar Producer..."
cd ../pulsar-producer
python3 pulsar-producer.py
