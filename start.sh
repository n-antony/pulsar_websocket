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

# Print Current Working Directory
echo "📂 Current Working Directory:"
pwd

# ✅ **Install OpenJDK 17 if not installed**
if ! command -v java &> /dev/null; then
    echo "📥 Installing OpenJDK 17..."
    curl -LO "https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.tar.gz"
    tar -xzf jdk-17.0.12_linux-x64_bin.tar.gz -C /opt/render/project/src/
    export JAVA_HOME="/opt/render/project/src/jdk-17.0.12"
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# ✅ **Verify Java Installation**
echo "🛠️ Java Version:"
java -version

# ✅ **Move to project directory**
cd /opt/render/project/src/
echo "📂 Moved to project directory: $(pwd)"

# ✅ **Pulsar Download and Extraction**
if [ ! -d "/opt/render/project/src/apache-pulsar-4.0.3" ]; then
    echo "📥 Downloading Apache Pulsar..."
    
    # Download the Pulsar binary tar file
    curl -o apache-pulsar-4.0.3-bin.tar.gz "https://downloads.apache.org/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz"

    # ✅ **Print file size of the downloaded Pulsar tar file**
    echo "📂 Checking Pulsar Tar File Size..."
    ls -lh apache-pulsar-4.0.3-bin.tar.gz

    # ✅ **Extract the Pulsar tar file**
    echo "📦 Extracting Pulsar..."
    tar -xzf apache-pulsar-4.0.3-bin.tar.gz

    # ✅ **Verify extraction by listing files**
    echo "📂 Contents after extraction:"
    ls -lh

    # ✅ **Ensure correct folder renaming**
    if [ -d "/opt/render/project/src/apache-pulsar-4.0.3-bin" ]; then
        mv /opt/render/project/src/apache-pulsar-4.0.3-bin /opt/render/project/src/apache-pulsar-4.0.3
        echo "✅ Pulsar folder renamed to: /opt/render/project/src/apache-pulsar-4.0.3"
    else
        echo "❌ ERROR: Pulsar extraction failed. Exiting..."
        exit 1
    fi
fi

# ✅ **Verify Pulsar Binary Exists**
if [ ! -f "/opt/render/project/src/apache-pulsar-4.0.3/bin/pulsar" ]; then
    echo "❌ ERROR: Pulsar binary is still missing after extraction! Exiting..."
    ls -l /opt/render/project/src/apache-pulsar-4.0.3
    exit 1
fi

# ✅ **Ensure the conf directory exists**
if [ ! -d "/opt/render/project/src/apache-pulsar-4.0.3/conf" ]; then
    echo "❌ Pulsar conf directory missing! Creating conf directory..."
    mkdir -p /opt/render/project/src/apache-pulsar-4.0.3/conf
fi

# ✅ **Copy the standalone configuration if available**
if [ -f "/opt/render/project/src/pulsar-config/standalone.conf" ]; then
    echo "⚙️ Updating Pulsar standalone configuration..."
    cp /opt/render/project/src/pulsar-config/standalone.conf /opt/render/project/src/apache-pulsar-4.0.3/conf/standalone.conf
fi

# ✅ **Debug Pulsar directory**
echo "🛠️ Pulsar Directory Contents:"
ls -l /opt/render/project/src/apache-pulsar-4.0.3

# ✅ **Print current working directory before running Pulsar**
echo "📂 Current Working Directory:"
pwd

# ✅ **Print directory structure before starting Pulsar**
if command -v tree &> /dev/null; then
    echo "📂 Directory Structure Before Pulsar Start:"
    tree /opt/render/project/src/apache-pulsar-4.0.3
else
    echo "📂 (Tree command not installed, listing structure instead)"
    find /opt/render/project/src/apache-pulsar-4.0.3 -print
fi

# ✅ **Start Pulsar in standalone mode**
echo "🚀 Starting Pulsar in standalone mode..."
cd /opt/render/project/src/apache-pulsar-4.0.3
echo "📂 Moved to Pulsar directory: $(pwd)"

# ✅ **Double-check that `bin/pulsar` exists before running**
if [ ! -f "bin/pulsar" ]; then
    echo "❌ ERROR: Pulsar binary is missing in $(pwd)/bin/"
    ls -l bin
    exit 1
fi

ls -l bin  # ✅ **Debug: Check if `bin` directory exists**
bin/pulsar standalone --no-stream-storage &

# ✅ **Wait for Pulsar to fully start**
sleep 15

# ✅ **Move back to the main project directory**
cd /opt/render/project/src/
echo "📂 Moved back to main project directory: $(pwd)"

# ✅ **Start the Pulsar producer script**
if [ -f "/opt/render/project/src/pulsar-producer.py" ]; then
    echo "📡 Starting Pulsar Producer..."
    python3 /opt/render/project/src/pulsar-producer.py &
else
    echo "❌ Pulsar Producer script not found!"
fi

echo "✅ Pulsar and Producer started successfully!"
