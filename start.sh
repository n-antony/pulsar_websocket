#!/bin/bash

set -e  # Exit script on error

echo "🚀 Starting Pulsar Deployment..."

# ✅ **Set Java memory limits**
export PULSAR_MEM="-Xms512m -Xmx1024m -XX:MaxDirectMemorySize=1024m"

# ✅ **Ensure Java is Installed & Verified**
if ! command -v java &> /dev/null; then
    echo "📥 Installing OpenJDK 17..."
    curl -LO "https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.tar.gz"
    tar -xzf jdk-17.0.12_linux-x64_bin.tar.gz
    export JAVA_HOME="/opt/render/project/src/jdk-17.0.12"
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# ✅ **Verify Java Installation**
echo "🛠️ Java Version:"
java -version || { echo "❌ ERROR: Java installation failed! Exiting..."; exit 1; }

# ✅ **Set Java Home and PATH**
export JAVA_HOME="/opt/render/project/src/jdk-17.0.12"
export PATH="$JAVA_HOME/bin:$PATH"

# ✅ **Move to project directory**
cd /opt/render/project/src/
echo "📂 Moved to project directory: $(pwd)"

# ✅ **Set Pulsar directory variables**
export PULSAR_DIR="/opt/render/project/src/apache-pulsar-4.0.3"
export PULSAR_METADATA_STORE="rocksdb://$PULSAR_DIR/data/metadata"
export PULSAR_CONFIG_METADATA_STORE="rocksdb://$PULSAR_DIR/data/metadata"

# ✅ **Debugging Paths**
echo "🔍 Debugging Paths:"
echo "📂 JAVA_HOME: $JAVA_HOME"
echo "📂 PATH: $PATH"
echo "📂 PULSAR_DIR: $PULSAR_DIR"
echo "📂 Current Working Directory: $(pwd)"

# ✅ **Ensure Pulsar is properly extracted**
if [ ! -d "$PULSAR_DIR" ] || [ ! -f "$PULSAR_DIR/bin/pulsar" ]; then
    echo "❌ Pulsar directory or binary missing! Re-extracting..."

    # ✅ **Remove any incomplete Pulsar directory**
    rm -rf "$PULSAR_DIR"

    # ✅ **Ensure Pulsar tarball is downloaded**
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

# ✅ **Copy standalone configuration if available**
CONFIG_FILE="$PULSAR_DIR/conf/standalone.conf"

if [ -f "pulsar-config/standalone.conf" ]; then
    echo "⚙️ Updating Pulsar standalone configuration..."
    cp pulsar-config/standalone.conf "$CONFIG_FILE"
fi

# ✅ **Fix metadataStoreUrl Formatting Safely**
echo "🛠 Fixing metadataStoreUrl format..."

# Remove any existing incorrect lines to prevent duplication
sed -i '/^metadataStoreUrl=/d' "$CONFIG_FILE"
sed -i '/^configurationMetadataStoreUrl=/d' "$CONFIG_FILE"

# Add correct lines at the end
echo "metadataStoreUrl=$PULSAR_METADATA_STORE" >> "$CONFIG_FILE"
echo "configurationMetadataStoreUrl=$PULSAR_CONFIG_METADATA_STORE" >> "$CONFIG_FILE"

# ✅ **Modify standalone.conf settings**
declare -A CONFIG_VARS=(
    ["clusterName"]="standalone-cluster"
    ["webServicePort"]="8080"
    ["webSocketServicePort"]="8081"
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

# ✅ **Ensure Java Version is Correct for Pulsar**
JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
if [[ "$JAVA_VERSION" < "17" ]]; then
    echo "❌ ERROR: Pulsar requires Java 17 or later! Detected: Java $JAVA_VERSION"
    exit 1
fi

# ✅ **Start Pulsar in standalone mode**
echo "🚀 Starting Pulsar in standalone mode..."
cd "$PULSAR_DIR"
echo "📂 Moved to Pulsar directory: $(pwd)"

# ✅ **Run Pulsar in the foreground to prevent Render restarts**
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

# ✅ **Prevent Render from restarting**
echo "🛠 Keeping container running to avoid restart..."
tail -f /dev/null
