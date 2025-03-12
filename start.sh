#!/bin/bash

set -e  # Exit script on error

echo "🚀 Starting Pulsar Deployment..."

# Set Java memory limits for Pulsar
export PULSAR_MEM="-Xms512m -Xmx1024m -XX:MaxDirectMemorySize=1024m"

# Set Java Home and PATH
export JAVA_HOME="/opt/render/project/src/jdk-17.0.12"
export PATH="$JAVA_HOME/bin:$PATH"

# ✅ **Set Pulsar directory variable**
export PULSAR_DIR="/opt/render/project/src/apache-pulsar-4.0.3"

# ✅ **Ensure absolute paths are correctly set**
export PULSAR_METADATA_STORE="rocksdb://$PULSAR_DIR/data/metadata"
export PULSAR_CONFIG_METADATA_STORE="rocksdb://$PULSAR_DIR/data/metadata"

# Debugging Paths
echo "🔍 Debugging Paths:"
echo "📂 JAVA_HOME: $JAVA_HOME"
echo "📂 PATH: $PATH"
echo "📂 PULSAR_DIR: $PULSAR_DIR"
echo "📂 PULSAR_METADATA_STORE: $PULSAR_METADATA_STORE"
echo "📂 Current Working Directory: $(pwd)"

# ✅ **Ensure Pulsar directories exist**
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
    echo "❌ ERROR: Pulsar conf directory missing! Creating conf directory..."
    mkdir -p "$PULSAR_DIR/conf"
fi

# ✅ **Copy the standalone configuration if available**
CONFIG_FILE="$PULSAR_DIR/conf/standalone.conf"

if [ -f "pulsar-config/standalone.conf" ]; then
    echo "⚙️ Updating Pulsar standalone configuration..."
    cp pulsar-config/standalone.conf "$CONFIG_FILE"
fi

# ✅ **Fix metadataStoreUrl format safely**
if grep -q "metadataStoreUrl=" "$CONFIG_FILE"; then
    echo "🛠 Fixing metadataStoreUrl format..."
    sed -i "s|metadataStoreUrl=.*|metadataStoreUrl=$PULSAR_METADATA_STORE|" "$CONFIG_FILE"
    sed -i "s|configurationMetadataStoreUrl=.*|configurationMetadataStoreUrl=$PULSAR_CONFIG_METADATA_STORE|" "$CONFIG_FILE"
else
    echo "metadataStoreUrl=$PULSAR_METADATA_STORE" >> "$CONFIG_FILE"
    echo "configurationMetadataStoreUrl=$PULSAR_CONFIG_METADATA_STORE" >> "$CONFIG_FILE"
fi

# ✅ **Modify standalone.conf settings (ensuring no duplication)**
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

echo "✅ Metadata store paths verified."

# ✅ **Wipe old data if any issues detected**
echo "🛠 Cleaning previous standalone data..."
rm -rf "$PULSAR_DIR/data/standalone"

# ✅ **Verify Pulsar bin directory exists**
if [ ! -f "$PULSAR_DIR/bin/pulsar" ]; then
    echo "❌ ERROR: Pulsar binary is missing! Exiting..."
    exit 1
fi

# ✅ **Start Pulsar in standalone mode (Foreground Mode)**
echo "🚀 Starting Pulsar in standalone mode..."
cd "$PULSAR_DIR"
echo "📂 Moved to Pulsar directory: $(pwd)"

# Run Pulsar in the foreground (fixes Render's auto-restart issue)
exec ./bin/pulsar standalone --wipe-data
