#!/bin/bash

set -e  # Exit script on error

echo "🚀 Starting Pulsar Deployment..."

# Set Java memory limits for Pulsar
export PULSAR_MEM="-Xms512m -Xmx1024m -XX:MaxDirectMemorySize=1024m"

# Set Java Home and PATH
export JAVA_HOME="/opt/render/project/src/jdk-17.0.12"
export PATH="$JAVA_HOME/bin:$PATH"

# ✅ Print Paths for Debugging
echo "🔍 Debugging Paths:"
echo "📂 JAVA_HOME: $JAVA_HOME"
echo "📂 PATH: $PATH"
echo "📂 Pulsar Directory: /opt/render/project/src/apache-pulsar-4.0.3"
echo "📂 Standalone Config Path: /opt/render/project/src/pulsar-config/standalone.conf"
echo "📂 Pulsar Producer Script: /opt/render/project/src/pulsar-producer.py"
echo ""

# ✅ Install OpenJDK 17 if not installed
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

# ✅ Print Java Version for Debugging
echo "🛠️ Java Version:"
java -version || echo "❌ Java not installed!"

# ✅ Download and extract Pulsar if not already available
if [ ! -d "/opt/render/project/src/apache-pulsar-4.0.3" ]; then
    echo "📥 Downloading and extracting Apache Pulsar..."
    curl -LO "https://downloads.apache.org/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz"
    tar xzf apache-pulsar-4.0.3-bin.tar.gz

    # Move extracted Pulsar folder to the correct location
    if [ -d "apache-pulsar-4.0.3" ]; then
        mv apache-pulsar-4.0.3 /opt/render/project/src/
    fi
fi

# ✅ Navigate to Pulsar directory
PULSAR_DIR="/opt/render/project/src/apache-pulsar-4.0.3"
if [ ! -d "$PULSAR_DIR" ]; then
    echo "❌ Pulsar directory not found: $PULSAR_DIR"
    exit 1
fi
cd "$PULSAR_DIR"

# ✅ Print Pulsar Directory Listing for Debugging
echo "🛠️ Pulsar Directory Contents:"
ls -l || echo "❌ Pulsar directory not found!"

# ✅ Ensure conf directory exists before copying
if [ -d "conf" ]; then
    echo "⚙️ Using custom Pulsar standalone configuration..."
    if [ -f "/opt/render/project/src/pulsar-config/standalone.conf" ]; then
        cp /opt/render/project/src/pulsar-config/standalone.conf conf/standalone.conf
    else
        echo "❌ Custom standalone.conf not found. Using default."
    fi
else
    echo "❌ Pulsar conf directory missing! Creating conf directory..."
    mkdir -p conf
fi

# ✅ Ensure bin directory exists before running Pulsar
if [ ! -f "bin/pulsar" ]; then
    echo "❌ Pulsar binary not found: bin/pulsar"
    exit 1
fi

# ✅ Start Pulsar in standalone mode
echo "🚀 Starting Pulsar in standalone mode..."
bin/pulsar standalone --no-stream-storage &

# Wait for Pulsar to fully start
sleep 15

# ✅ Move back to the main project directory
cd /opt/render/project/src/

# ✅ Ensure the producer script exists
if [ -f "pulsar-producer.py" ]; then
    echo "📡 Starting Pulsar Producer..."
    python3 pulsar-producer.py &
else
    echo "❌ Pulsar Producer script not found!"
    exit 1
fi

echo "✅ Pulsar and Producer started successfully!"
