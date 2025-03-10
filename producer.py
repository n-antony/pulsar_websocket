import pulsar
import json
import time
import random

# Pulsar Broker WebSocket URL (Replace with Render's actual domain)
PULSAR_URL = "wss://your-pulsar-service.onrender.com:8443"

# Topics for different customer IDs
TOPICS = [
    "persistent://public/default/customer-12345",
    "persistent://public/default/customer-67890",
    "persistent://public/default/customer-98765",
]

# Create a Pulsar client
client = pulsar.Client(PULSAR_URL)

# Create producers for different topics
producers = {topic: client.create_producer(topic) for topic in TOPICS}

print("✅ Pulsar Producer is running...")

try:
    while True:
        for topic in TOPICS:
            # Create a random event
            event = {
                "customer_id": topic.split("-")[-1],  # Extract customer ID from topic
                "event_type": random.choice(["pickup", "putback", "exit"]),
                "item": {
                    "name": random.choice(["Milk", "Bread", "Eggs", "Cheese", "Chicken"]),
                    "barcode": str(random.randint(1000000000, 9999999999)),
                    "weight": f"{random.randint(1, 5)}kg",
                },
                "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            }

            # Send message to Pulsar topic
            producers[topic].send(json.dumps(event).encode('utf-8'))
            print(f"📤 Sent event to {topic}: {event}")

        time.sleep(5)  # Send a message every 5 seconds

except KeyboardInterrupt:
    print("❌ Stopping Pulsar Producer...")
    client.close()
