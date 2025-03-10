#!/bin/bash

# Set environment variables
export JAVA_HOME=$PWD/jdk-17
export PATH=$JAVA_HOME/bin:$PATH

# Check if Java is already installed
if [ ! -d "$JAVA_HOME" ]; then
  echo "Downloading and extracting OpenJDK 17..."
  curl -LO https://download.java.net/java/GA/jdk17/0/GPL/openjdk-17_linux-x64_bin.tar.gz
  tar -xzf openjdk-17_linux-x64_bin.tar.gz
  mv jdk-17.* jdk-17
fi

# Download & extract Pulsar if not already present
if [ ! -d "apache-pulsar-4.0.3" ]; then
  echo "Downloading and extracting Pulsar..."
  curl -LO "https://www.apache.org/dyn/closer.lua/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz?action=download"
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
