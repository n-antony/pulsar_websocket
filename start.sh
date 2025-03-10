#!/bin/bash

set -e  # Exit script on error

echo "🚀 Starting Pulsar Deployment..."

# Set Java memory limits for Pulsar
export PULSAR_MEM="-Xms512m -Xmx1024m -XX:MaxDirectMemorySize=1024m"

# Set Java Home and PATH
export JAVA_HOME="/opt/render/project/src/jdk-17.0.12"
export PATH="$JAVA_HOME/bin:$PATH"

# Install OpenJDK if not installed
if ! command -v java &> /dev/null; then
    echo "📥 Installing OpenJDK 17..."
    curl -LO "https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.tar.gz"
    tar -xvzf jdk-17.0.12_linux-x64_bin.tar.gz
    mv jdk-17.0.12 /opt/render/project/src/jdk-17.0.12
    export JAVA_HOME="/opt/render/project/src/jdk-17.0.12"
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# Download and extract Pulsar if not already available
if [ ! -d "apache-pulsar-4.0.3" ]; then
    echo "📥 Downloading and extracting Apache Pulsar..."
    curl -LO "https://www.apache.org/dyn/closer.lua/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz?action=download"
    tar xvfz apache-pulsar-4.0.3-bin.tar.gz
fi

# Navigate to Pulsar directory
cd apache-pulsar-4.0.3

# Copy the updated standalone configuration if available
if [ -f "../pulsar-config/standalone.conf" ]; then
    echo "⚙️ Updating Pulsar standalone configuration..."
    cp ../pulsar-config/standalone.conf conf/standalone.conf
fi

# Start Pulsar in standalone mode
echo "🚀 Starting Pulsar in standalone mode..."
bin/pulsar standalone --no-stream-storage &

# Wait for Pulsar to fully start
sleep 15

# Move back to the main project directory
cd ..

# Start the Pulsar producer script
echo "📡 Starting Pulsar Producer..."
python3 pulsar-producer.py &

echo "✅ Pulsar and Producer started successfully!"
