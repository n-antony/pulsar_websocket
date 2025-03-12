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

# ✅ **Set Pulsar directory variable**
export PULSAR_DIR="/opt/render/project/src/apache-pulsar-4.0.3"

# ✅ **Check if Pulsar is already extracted**
if [ -d "$PULSAR_DIR" ]; then
    echo "✅ Pulsar directory found."
else
    echo "❌ Pulsar directory missing! Checking tarball..."
    
    # ✅ **Check if tarball exists**
    if [ ! -f "apache-pulsar-4.0.3-bin.tar.gz" ]; then
        echo "📥 Tarball missing! Downloading Apache Pulsar..."
        curl -o apache-pulsar-4.0.3-bin.tar.gz "https://downloads.apache.org/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz"
    else
        echo "✅ Tarball found, skipping download."
    fi

    echo "📦 Extracting Pulsar..."
    tar -xzf apache-pulsar-4.0.3-bin.tar.gz
fi

# ✅ **Ensure Pulsar `bin` directory exists**
if [ ! -d "$PULSAR_DIR/bin" ]; then
    echo "❌ ERROR: Pulsar bin directory is missing! Re-extracting Pulsar..."
    rm -rf "$PULSAR_DIR"

    echo "📥 Checking for Pulsar tarball..."
    if [ ! -f "apache-pulsar-4.0.3-bin.tar.gz" ]; then
        echo "📥 Tarball missing! Re-downloading..."
        curl -o apache-pulsar-4.0.3-bin.tar.gz "https://downloads.apache.org/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz"
    fi

    echo "📦 Extracting Pulsar again..."
    tar -xzf apache-pulsar-4.0.3-bin.tar.gz

    # Check if extraction succeeded
    if [ ! -d "$PULSAR_DIR/bin" ]; then
        echo "❌ ERROR: Pulsar bin directory is still missing after extraction! Exiting..."
        exit 1
    fi
fi

echo "📂 Pulsar detected at: $PULSAR_DIR"

# ✅ **Ensure the `data/` directory exists before setting permissions**
if [ ! -d "$PULSAR_DIR/data" ]; then
    echo "❌ Data directory missing! Creating..."
    mkdir -p "$PULSAR_DIR/data"
fi

# ✅ **Ensure Pulsar has write permissions**
chmod -R 777 "$PULSAR_DIR/data"

# ✅ **Ensure Pulsar conf directory exists**
if [ ! -d "$PULSAR_DIR/conf" ]; then
    echo "❌ ERROR: Pulsar conf directory missing! Creating conf directory..."
    mkdir -p "$PULSAR_DIR/conf"
fi

# ✅ **Copy the standalone configuration if available**
if [ -f "pulsar-config/standalone.conf" ]; then
    echo "⚙️ Updating Pulsar standalone configuration..."
    cp pulsar-config/standalone.conf "$PULSAR_DIR/conf/standalone.conf"
fi

CONFIG_FILE="$PULSAR_DIR/conf/standalone.conf"

# ✅ **Modify standalone.conf settings**
declare -A CONFIG_VARS=(
    ["clusterName"]="standalone-cluster"
    ["webServicePort"]="8080"
    ["webSocketServicePort"]="8081"
    ["metadataStoreUrl"]="rocksdb://$PULSAR_DIR/data/metadata"
    ["configurationMetadataStoreUrl"]="rocksdb://$PULSAR_DIR/data/metadata"
)

for key in "${!CONFIG_VARS[@]}"; do
    value=${CONFIG_VARS[$key]}
    if grep -q "^$key=" "$CONFIG_FILE"; then
        sed -i "s|^$key=.*|$key=$value|" "$CONFIG_FILE"
    else
        echo "$key=$value" >> "$CONFIG_FILE"
    fi
done

# ✅ **Ensure metadata directory exists**
echo "🔍 Checking Metadata Directory Structure..."
if [ ! -d "$PULSAR_DIR/data/metadata" ]; then
    echo "❌ Metadata directory missing! Creating..."
    mkdir -p "$PULSAR_DIR/data/metadata"
fi

# ✅ **Verify metadata paths**
if grep -q "metadataStoreUrl=" "$CONFIG_FILE"; then
    sed -i 's|metadataStoreUrl=rocksdb:///|metadataStoreUrl=rocksdb://'"$PULSAR_DIR"'/data/metadata|' "$CONFIG_FILE"
    sed -i 's|configurationMetadataStoreUrl=rocksdb:///|configurationMetadataStoreUrl=rocksdb://'"$PULSAR_DIR"'/data/metadata|' "$CONFIG_FILE"
fi

echo "✅ Metadata store paths verified."

# ✅ **Set environment variables**
export PULSAR_METADATA_STORE="rocksdb://$PULSAR_DIR/data/metadata"
export PULSAR_CONFIG_METADATA_STORE="rocksdb://$PULSAR_DIR/data/metadata"

echo "🔍 PULSAR_METADATA_STORE: $PULSAR_METADATA_STORE"
echo "🔍 PULSAR_CONFIG_METADATA_STORE: $PULSAR_CONFIG_METADATA_STORE"

# ✅ **Wipe old data if any issues detected**
echo "🛠 Cleaning previous standalone data..."
rm -rf "$PULSAR_DIR/data/standalone"

# ✅ **Start Pulsar in standalone mode**
echo "🚀 Starting Pulsar in standalone mode..."
cd "$PULSAR_DIR"
echo "📂 Moved to Pulsar directory: $(pwd)"

./bin/pulsar standalone --wipe-data &

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
