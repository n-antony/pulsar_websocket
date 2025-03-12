#!/bin/bash

set -e  # Exit script on error

echo "🚀 Starting Pulsar Deployment..."

# Set Java memory limits for Pulsar
export PULSAR_MEM="-Xms512m -Xmx1024m -XX:MaxDirectMemorySize=1024m"

# Set Java Home and PATH
export JAVA_HOME="/opt/render/project/src/jdk-17.0.12"
export PATH="$JAVA_HOME/bin:$PATH"

# ✅ **Move to project directory**
cd /opt/render/project/src/
echo "📂 Moved to project directory: $(pwd)"

# ✅ **Set Pulsar directory variable**
export PULSAR_DIR="/opt/render/project/src/apache-pulsar-4.0.3"
export PULSAR_METADATA_STORE="rocksdb://$PULSAR_DIR/data/metadata"
export PULSAR_CONFIG_METADATA_STORE="rocksdb://$PULSAR_DIR/data/metadata"

# Debugging Paths
echo "🔍 Debugging Paths:"
echo "📂 JAVA_HOME: $JAVA_HOME"
echo "📂 PATH: $PATH"
echo "📂 PULSAR_DIR: $PULSAR_DIR"
echo "📂 Current Working Directory: $(pwd)"

# ✅ **Ensure Pulsar is extracted properly**
if [ ! -d "$PULSAR_DIR" ] || [ ! -f "$PULSAR_DIR/bin/pulsar" ]; then
    echo "❌ Pulsar directory or binary missing! Re-extracting..."

    # ✅ **Remove any partially extracted directory**
    rm -rf "$PULSAR_DIR"

    # ✅ **Ensure tarball is downloaded**
    if [ ! -f "apache-pulsar-4.0.3-bin.tar.gz" ]; then
        echo "📥 Tarball missing! Downloading Apache Pulsar..."
        curl -o apache-pulsar-4.0.3-bin.tar.gz "https://downloads.apache.org/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz"
    fi

    echo "📦 Extracting Pulsar..."
    tar -xzf apache-pulsar-4.0.3-bin.tar.gz

    # ✅ **Verify if extraction succeeded**
    if [ ! -f "$PULSAR_DIR/bin/pulsar" ]; then
        echo "❌ ERROR: Pulsar binary is still missing after extraction! Exiting..."
        exit 1
    fi
fi

echo "✅ Pulsar successfully extracted."
echo "📂 Pulsar detected at: $PULSAR_DIR"

# ✅ **Ensure required directories exist**
for dir in "$PULSAR_DIR/data" "$PULSAR_DIR/data/metadata"; do
    if [ ! -d "$dir" ]; then
        echo "❌ $dir missing! Creating..."
        mkdir -p "$dir"
    fi
done

# ✅ **Ensure Pulsar has write permissions**
chmod -R 777 "$PULSAR_DIR/data"

# ✅ **Ensure Pulsar conf directory exists**
if [ ! -d "$PULSAR_DIR/conf" ]; then
    echo "❌ ERROR: Pulsar conf directory missing! Creating..."
    mkdir -p "$PULSAR_DIR/conf"
fi

# ✅ **Copy the standalone configuration if available**
CONFIG_FILE="$PULSAR_DIR/conf/standalone.conf"

if [ -f "pulsar-config/standalone.conf" ]; then
    echo "⚙️ Updating Pulsar standalone configuration..."
    cp pulsar-config/standalone.conf "$CONFIG_FILE"
fi

# ✅ **Modify standalone.conf settings**
declare -A CONFIG_VARS=(
    ["clusterName"]="standalone-cluster"
    ["webServicePort"]="8080"
    ["webSocketServicePort"]="8081"
    ["metadataStoreUrl"]="$PULSAR_METADATA_STORE"
    ["configurationMetadataStoreUrl"]="$PULSAR_CONFIG_METADATA_STORE"
)

for key in "${!CONFIG_VARS[@]}"; do
    value=${CONFIG_VARS[$key]}
    if grep -q "^$key=" "$CONFIG_FILE"; then
        sed -i "s|^$key=.*|$key=$value|" "$CONFIG_FILE"
    else
        echo "$key=$value" >> "$CONFIG_FILE"
    fi
done

# ✅ **Verify metadata paths**
if grep -q "metadataStoreUrl=rocksdb:///" "$CONFIG_FILE"; then
    echo "❌ Incorrect metadataStoreUrl format detected! Fixing..."
    sed -i "s|metadataStoreUrl=rocksdb:///|metadataStoreUrl=$PULSAR_METADATA_STORE|" "$CONFIG_FILE"
    sed -i "s|configurationMetadataStoreUrl=rocksdb:///|configurationMetadataStoreUrl=$PULSAR_CONFIG_METADATA_STORE|" "$CONFIG_FILE"
fi

echo "✅ Metadata store paths verified."

# ✅ **Wipe old data if any issues detected**
echo "🛠 Cleaning previous standalone data..."
rm -rf "$PULSAR_DIR/data/standalone"

# ✅ **Start Pulsar in standalone mode**
echo "🚀 Starting Pulsar in standalone mode..."
cd "$PULSAR_DIR"
echo "📂 Moved to Pulsar directory: $(pwd)"

# **Run Pulsar in the foreground so Render doesn’t restart it**
./bin/pulsar standalone --wipe-data

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

# ✅ **Keep script running to prevent Render from restarting**
echo "🛠 Keeping container running to avoid restart..."
tail -f /dev/null
