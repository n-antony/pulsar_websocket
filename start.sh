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
    tar -xzf jdk-17.0.12_linux-x64_bin.tar.gz

    # Ensure Java is moved only if it doesn't exist
    if [ ! -d "/opt/render/project/src/jdk-17.0.12" ]; then
        mv jdk-17.0.12 /opt/render/project/src/
    fi

    export JAVA_HOME="/opt/render/project/src/jdk-17.0.12"
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# Download and extract Pulsar if not already available
if [ ! -d "/opt/render/project/src/apache-pulsar-4.0.3" ]; then
    echo "📥 Downloading and extracting Apache Pulsar..."
    curl -LO "https://www.apache.org/dyn/closer.lua/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz?action=download"
    tar xzf apache-pulsar-4.0.3-bin.tar.gz

    # Move extracted Pulsar folder to the correct location
    if [ ! -d "/opt/render/project/src/apache-pulsar-4.0.3" ]; then
        mv apache-pulsar-4.0.3 /opt/render/project/src/
    fi
fi

# Navigate to Pulsar directory
cd /opt/render/project/src/apache-pulsar-4.0.3

# ✅ Ensure conf directory exists before copying
if [ -d "conf" ]; then
    echo "⚙️ Using custom Pulsar standalone configuration..."
    if [ -f "/opt/render/project/src/pulsar-config/standalone.conf" ]; then
        cp /opt/render/project/src/pulsar-config/standalone.conf conf/standalone.conf
    else
        echo "❌ Custom standalone.conf not found. Using default."
    fi
else
    echo "❌ Pulsar conf directory missing!"
fi

# Start Pulsar in standalone mode
echo "🚀 Starting Pulsar in standalone mode..."
bin/pulsar standalone --no-stream-storage &

# Wait for Pulsar to fully start
sleep 15

# Move back to the main project directory
cd /opt/render/project/src/

# Start the Pulsar producer script
if [ -f "pulsar-producer.py" ]; then
    echo "📡 Starting Pulsar Producer..."
    python3 pulsar-producer.py &
else
    echo "❌ Pulsar Producer script not found!"
fi

echo "✅ Pulsar and Producer started successfully!"
