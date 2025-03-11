#!/bin/bash

set -e  # Exit script on error

echo "🚀 Starting Pulsar Deployment..."

# Set Java memory limits for Pulsar
export PULSAR_MEM="-Xms512m -Xmx1024m -XX:MaxDirectMemorySize=1024m"

# Set Java Home and PATH
export JAVA_HOME="/opt/render/project/src/jdk-17.0.12"
export PATH="$JAVA_HOME/bin:$PATH"

# Debugging Paths
echo "🔍 Debugging Paths:"
echo "📂 JAVA_HOME: $JAVA_HOME"
echo "📂 PATH: $PATH"
echo "📂 Pulsar Directory: /opt/render/project/src/apache-pulsar-4.0.3"
echo "📂 Standalone Config Path: /opt/render/project/src/pulsar-config/standalone.conf"
echo "📂 Pulsar Producer Script: /opt/render/project/src/pulsar-producer.py"

# Install OpenJDK 17 if not installed
if ! command -v java &> /dev/null; then
    echo "📥 Installing OpenJDK 17..."
    curl -LO "https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.tar.gz"
    tar -xzf jdk-17.0.12_linux-x64_bin.tar.gz -C /opt/render/project/src/
    export JAVA_HOME="/opt/render/project/src/jdk-17.0.12"
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# Verify Java Installation
echo "🛠️ Java Version:"
java -version

# Download and extract Pulsar if not already available
if [ ! -d "/opt/render/project/src/apache-pulsar-4.0.3" ]; then
    echo "📥 Downloading and extracting Apache Pulsar..."
    curl -o apache-pulsar.tar.gz "https://downloads.apache.org/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz"
    tar -xzf apache-pulsar.tar.gz -C /opt/render/project/src/
    
    # ✅ Ensure correct extracted folder name
    if [ -d "/opt/render/project/src/apache-pulsar-4.0.3-bin" ]; then
        mv /opt/render/project/src/apache-pulsar-4.0.3-bin /opt/render/project/src/apache-pulsar-4.0.3
    fi
fi

# Ensure the conf directory exists
if [ ! -d "/opt/render/project/src/apache-pulsar-4.0.3/conf" ]; then
    echo "❌ Pulsar conf directory missing! Creating conf directory..."
    mkdir -p /opt/render/project/src/apache-pulsar-4.0.3/conf
fi

# Copy the standalone configuration if available
if [ -f "/opt/render/project/src/pulsar-config/standalone.conf" ]; then
    echo "⚙️ Updating Pulsar standalone configuration..."
    cp /opt/render/project/src/pulsar-config/standalone.conf /opt/render/project/src/apache-pulsar-4.0.3/conf/standalone.conf
fi

# Debug Pulsar directory
echo "🛠️ Pulsar Directory Contents:"
ls -l /opt/render/project/src/apache-pulsar-4.0.3

# ✅ Check if `bin/pulsar` exists before starting
if [ ! -f "/opt/render/project/src/apache-pulsar-4.0.3/bin/pulsar" ]; then
    echo "❌ ERROR: Pulsar binary not found! Listing Pulsar directory contents..."
    ls -l /opt/render/project/src/apache-pulsar-4.0.3
    exit 1
fi

# ✅ Print current working directory before running Pulsar
echo "📂 Current Working Directory:"
pwd

# ✅ Print a directory tree (requires `tree` command)
if command -v tree &> /dev/null; then
    echo "📂 Directory Structure Before Pulsar Start:"
    tree /opt/render/project/src/apache-pulsar-4.0.3
else
    echo "📂 (Tree command not installed, listing structure instead)"
    find /opt/render/project/src/apache-pulsar-4.0.3 -print
fi

# Start Pulsar in standalone mode
echo "🚀 Starting Pulsar in standalone mode..."
cd /opt/render/project/src/apache-pulsar-4.0.3
ls -l bin  # ✅ Debug: Check if `bin` directory exists
bin/pulsar standalone --no-stream-storage &

# Wait for Pulsar to fully start
sleep 15

# Move back to the main project directory
cd /opt/render/project/src/

# Start the Pulsar producer script
if [ -f "/opt/render/project/src/pulsar-producer.py" ]; then
    echo "📡 Starting Pulsar Producer..."
    python3 /opt/render/project/src/pulsar-producer.py &
else
    echo "❌ Pulsar Producer script not found!"
fi

echo "✅ Pulsar and Producer started successfully!"
