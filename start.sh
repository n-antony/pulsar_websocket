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
echo "📂 Current Working Directory: $(pwd)"

# ✅ **Install OpenJDK 17 if not installed**
if ! command -v java &> /dev/null; then
    echo "📥 Installing OpenJDK 17..."
    curl -LO "https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.tar.gz"
    tar -xzf jdk-17.0.12_linux-x64_bin.tar.gz
    export JAVA_HOME="/opt/render/project/src/jdk-17.0.12"
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# ✅ **Verify Java Installation**
echo "🛠️ Java Version:"
java -version

# ✅ **Move to project directory**
cd /opt/render/project/src/
echo "📂 Moved to project directory: $(pwd)"

# ✅ **Check if Pulsar is already installed**
if [ ! -d "apache-pulsar-4.0.3" ]; then
    echo "📥 Downloading Apache Pulsar..."
    curl -o apache-pulsar-4.0.3-bin.tar.gz "https://downloads.apache.org/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz"
    echo "📦 Extracting Pulsar..."
    tar -xzf apache-pulsar-4.0.3-bin.tar.gz
else
    echo "✅ Pulsar directory already exists, skipping download."
fi

# ✅ **Detect Pulsar directory**
PULSAR_DIR=$(find . -maxdepth 1 -type d -name "apache-pulsar-*" | head -n 1)

if [ ! -d "$PULSAR_DIR" ]; then
    echo "❌ ERROR: Pulsar directory not found! Exiting..."
    exit 1
fi

echo "📂 Pulsar detected at: $PULSAR_DIR"

# ✅ **Ensure the Pulsar `bin/pulsar` exists**
if [ ! -f "$PULSAR_DIR/bin/pulsar" ]; then
    echo "❌ ERROR: Pulsar binary missing! Exiting..."
    ls -l "$PULSAR_DIR/bin"
    exit 1
fi

# ✅ **Ensure the binary is executable**
chmod +x "$PULSAR_DIR/bin/pulsar"

# ✅ **Preserve the `data` directory to prevent metadata loss**
if [ -d "$PULSAR_DIR/data" ]; then
    echo "🛠️ Pulsar data directory exists, preserving it..."
else
    echo "❌ ERROR: Pulsar data directory is missing! Creating a new one..."
    mkdir -p "$PULSAR_DIR/data"
fi

# ✅ **Check if metadata directory exists**
if [ -d "$PULSAR_DIR/data/metadata" ]; then
    echo "✅ Metadata directory exists: $PULSAR_DIR/data/metadata"
else
    echo "❌ Metadata directory missing! Initializing new metadata storage..."
    mkdir -p "$PULSAR_DIR/data/metadata"
fi

# ✅ **Ensure Pulsar has write permissions**
chmod -R 777 "$PULSAR_DIR/data"

# ✅ **Ensure the conf directory exists**
if [ ! -d "$PULSAR_DIR/conf" ]; then
    echo "❌ ERROR: Pulsar conf directory missing! Creating conf directory..."
    mkdir -p "$PULSAR_DIR/conf"
fi

# ✅ **Copy the standalone configuration if available**
if [ -f "pulsar-config/standalone.conf" ]; then
    echo "⚙️ Updating Pulsar standalone configuration..."
    cp pulsar-config/standalone.conf "$PULSAR_DIR/conf/standalone.conf"
fi

# ✅ **Modify standalone.conf to set clusterName**
if grep -q "clusterName=" "$PULSAR_DIR/conf/standalone.conf"; then
    sed -i 's/^clusterName=.*/clusterName=standalone-cluster/' "$PULSAR_DIR/conf/standalone.conf"
else
    echo "clusterName=standalone-cluster" >> "$PULSAR_DIR/conf/standalone.conf"
fi

# ✅ **Set WebSocket and Web Service Ports**
if grep -q "webServicePort=" "$PULSAR_DIR/conf/standalone.conf"; then
    sed -i 's/^webServicePort=.*/webServicePort=8080/' "$PULSAR_DIR/conf/standalone.conf"
else
    echo "webServicePort=8080" >> "$PULSAR_DIR/conf/standalone.conf"
fi

if grep -q "webSocketServicePort=" "$PULSAR_DIR/conf/standalone.conf"; then
    sed -i 's/^webSocketServicePort=.*/webSocketServicePort=8081/' "$PULSAR_DIR/conf/standalone.conf"
else
    echo "webSocketServicePort=8081" >> "$PULSAR_DIR/conf/standalone.conf"
fi

# ✅ **Print extracted Pulsar directory contents**
echo "🛠️ Pulsar Directory Contents:"
ls -l "$PULSAR_DIR"

# ✅ **Check if data directories exist**
echo "🔍 Checking Data Directory Structure:"
ls -l "$PULSAR_DIR/data"

# ✅ **Check if metadata directory exists**
echo "🔍 Checking Metadata Directory:"
ls -l "$PULSAR_DIR/data/metadata"

# ✅ **Start Pulsar in standalone mode**
echo "🚀 Starting Pulsar in standalone mode..."
cd "$PULSAR_DIR"
echo "📂 Moved to Pulsar directory: $(pwd)"

./bin/pulsar standalone --no-stream-storage &

# ✅ **Wait for Pulsar to fully start**
sleep 15

# ✅ **Move back to the main project directory**
cd /opt/render/project/src/
echo "📂 Moved back to main project directory: $(pwd)"

# ✅ **Start the Pulsar producer script**
if [ -f "pulsar-producer.py" ]; then
    echo "📡 Starting Pulsar Producer..."
    python3 pulsar-producer.py &
else
    echo "❌ Pulsar Producer script not found!"
fi

echo "✅ Pulsar and Producer started successfully!"
