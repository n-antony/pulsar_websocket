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

# ✅ **Delete existing Pulsar directory before re-downloading**
if [ -d "apache-pulsar-4.0.3" ]; then
    echo "⚠️ Existing Pulsar directory found! Deleting it..."
    rm -rf apache-pulsar-4.0.3
fi

# ✅ **Download Pulsar**
echo "📥 Downloading Apache Pulsar..."
curl -o apache-pulsar-4.0.3-bin.tar.gz "https://downloads.apache.org/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz"

# ✅ **Print file size of the downloaded Pulsar tar file**
echo "📂 Pulsar Tar File Size:"
ls -lh apache-pulsar-4.0.3-bin.tar.gz

# ✅ **Extract Pulsar in place**
echo "📦 Extracting Pulsar..."
tar -xzf apache-pulsar-4.0.3-bin.tar.gz

# ✅ **Detect Pulsar extraction folder**
PULSAR_DIR=$(find . -maxdepth 1 -type d -name "apache-pulsar-*" | head -n 1)

if [ ! -d "$PULSAR_DIR" ]; then
    echo "❌ ERROR: Pulsar extraction failed. Exiting..."
    exit 1
fi

echo "📂 Pulsar extracted to: $PULSAR_DIR"

# ✅ **Check if Pulsar `bin/pulsar` exists**
if [ ! -f "$PULSAR_DIR/bin/pulsar" ]; then
    echo "❌ ERROR: Pulsar binary is missing! Exiting..."
    ls -l "$PULSAR_DIR/bin"
    exit 1
fi

# ✅ **Ensure the binary is executable**
chmod +x "$PULSAR_DIR/bin/pulsar"

# ✅ **Ensure the conf directory exists**
if [ ! -d "$PULSAR_DIR/conf" ]; then
    echo "❌ Pulsar conf directory missing! Creating conf directory..."
    mkdir -p "$PULSAR_DIR/conf"
fi

# ✅ **Copy the updated standalone configuration**
if [ -f "pulsar-config/standalone.conf" ]; then
    echo "⚙️ Updating Pulsar standalone configuration..."
    cp pulsar-config/standalone.conf "$PULSAR_DIR/conf/standalone.conf"
fi

# ✅ **Print extracted Pulsar directory contents**
echo "🛠️ Pulsar Directory Contents:"
ls -l "$PULSAR_DIR"

# ✅ **Print directory structure before running Pulsar**
if command -v tree &> /dev/null; then
    echo "📂 Directory Structure Before Pulsar Start:"
    tree "$PULSAR_DIR"
else
    echo "📂 (Tree command not installed, listing structure instead)"
    find "$PULSAR_DIR" -print
fi

# ✅ **Ensure SSL Certificates Exist**
if [ ! -f "/etc/ssl/certs/render-cert.pem" ] || [ ! -f "/etc/ssl/private/render-key.pem" ]; then
    echo "❌ ERROR: SSL Certificates Missing! Ensure they are configured correctly."
    exit 1
fi

# ✅ **Start Pulsar with WebSocket Support**
echo "🚀 Starting Pulsar with WebSocket Support..."
cd "$PULSAR_DIR"
./bin/pulsar standalone --no-stream-storage &
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
