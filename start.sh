#!/bin/bash

set -e  # Exit script on error

echo "🚀 Starting Pulsar Deployment..."

# Set Java memory limits for Pulsar
export PULSAR_MEM="-Xms512m -Xmx1024m -XX:MaxDirectMemorySize=1024m"

# Set Java Home and PATH
export JAVA_HOME="/opt/render/project/src/jdk-17.0.12"
export PATH="$JAVA_HOME/bin:$PATH"

# ✅ Set Pulsar directory variable
export PULSAR_DIR="/opt/render/project/src/apache-pulsar-4.0.3"
export PULSAR_METADATA_STORE="rocksdb://$PULSAR_DIR/data/metadata"
export PULSAR_CONFIG_METADATA_STORE="rocksdb://$PULSAR_DIR/data/metadata"

# Debugging Paths
echo "🔍 Debugging Paths:"
echo "📂 JAVA_HOME: $JAVA_HOME"
echo "📂 PATH: $PATH"
echo "📂 PULSAR_DIR: $PULSAR_DIR"
echo "📂 PULSAR_METADATA_STORE: $PULSAR_METADATA_STORE"
echo "📂 Current Working Directory: $(pwd)"

# ✅ Ensure Pulsar is extracted
if [ ! -d "$PULSAR_DIR" ] || [ ! -f "$PULSAR_DIR/bin/pulsar" ]; then
    echo "❌ Pulsar is missing! Reinstalling..."
    
    # Remove corrupted installations
    rm -rf "$PULSAR_DIR"
    
    if [ ! -f "apache-pulsar-4.0.3-bin.tar.gz" ]; then
        echo "📥 Downloading Apache Pulsar..."
        curl -o apache-pulsar-4.0.3-bin.tar.gz "https://downloads.apache.org/pulsar/pulsar-4.0.3/apache-pulsar-4.0.3-bin.tar.gz"
    fi
    
    echo "📦 Extracting Pulsar..."
    tar -xzf apache-pulsar-4.0.3-bin.tar.gz
fi

# ✅ Verify Pulsar bin directory exists
if [ ! -f "$PULSAR_DIR/bin/pulsar" ]; then
    echo "❌ ERROR: Pulsar binary is missing after extraction! Exiting..."
    exit 1
fi

echo "📂 Pulsar detected at: $PULSAR_DIR"

# ✅ Ensure data directories exist
for dir in "$PULSAR_DIR/data" "$PULSAR_DIR/data/metadata"; do
    if [ ! -d "$dir" ]; then
        echo "❌ $dir missing! Creating..."
        mkdir -p "$dir"
    fi
done

chmod -R 777 "$PULSAR_DIR/data"

# ✅ Ensure conf directory exists
if [ ! -d "$PULSAR_DIR/conf" ]; then
    echo "❌ ERROR: Pulsar conf directory missing! Creating..."
    mkdir -p "$PULSAR_DIR/conf"
fi

# ✅ Copy the standalone configuration if available
CONFIG_FILE="$PULSAR_DIR/conf/standalone.conf"
if [ -f "pulsar-config/standalone.conf" ]; then
    echo "⚙️ Updating Pulsar standalone configuration..."
    cp pulsar-config/standalone.conf "$CONFIG_FILE"
fi

# ✅ Fix metadataStoreUrl format
if grep -q "metadataStoreUrl=" "$CONFIG_FILE"; then
    echo "🛠 Fixing metadataStoreUrl format..."
    sed -i "s|metadataStoreUrl=.*|metadataStoreUrl=$PULSAR_METADATA_STORE|" "$CONFIG_FILE"
    sed -i "s|configurationMetadataStoreUrl=.*|configurationMetadataStoreUrl=$PULSAR_CONFIG_METADATA_STORE|" "$CONFIG_FILE"
else
    echo "metadataStoreUrl=$PULSAR_METADATA_STORE" >> "$CONFIG_FILE"
    echo "configurationMetadataStoreUrl=$PULSAR_CONFIG_METADATA_STORE" >> "$CONFIG_FILE"
fi

echo "✅ Metadata store paths verified."

# ✅ Ensure previous Pulsar data is cleaned
echo "🛠 Cleaning previous standalone data..."
rm -rf "$PULSAR_DIR/data/standalone"

# ✅ Start Pulsar in standalone mode (Foreground Mode)
echo "🚀 Starting Pulsar in standalone mode..."
cd "$PULSAR_DIR"
echo "📂 Moved to Pulsar directory: $(pwd)"

# Run in foreground to prevent Render from restarting
exec ./bin/pulsar standalone --wipe-data
