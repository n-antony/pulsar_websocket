import pulsar
import json
import time
import random
import logging

# Configure Logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Pulsar broker URL (Update this if needed)
PULSAR_URL = "pulsar://localhost:6650"  # Change this if using an external Pulsar instance

# Topics for different customers
CUSTOMER_TOPICS = ["customer-1001", "customer-1002", "customer-1003"]

# Function to produce messages
def produce_messages():
    logging.info("🚀 Connecting to Pulsar broker at %s...", PULSAR_URL)

    try:
        client = pulsar.Client(PULSAR_URL)
        producers = {topic: client.create_producer(topic) for topic in CUSTOMER_TOPICS}
        
        while True:
            for topic in CUSTOMER_TOPICS:
                event = {
                    "timestamp": time.time(),
                    "customer_id": topic,
                    "event_type": random.choice(["pickup", "putback", "exit"]),
                    "item": {
                        "name": random.choice(["Milk", "Bread", "Eggs", "Cheese", "Chicken"]),
                        "barcode": str(random.randint(1000000000, 9999999999)),
                        "weight": f"{random.randint(1, 5)}kg"
                    }
                }

                message = json.dumps(event)
                producers[topic].send(message.encode("utf-8"))

                logging.info(f"📡 Sent message to {topic}: {message}")

            time.sleep(5)  # Send messages every 5 seconds

    except Exception as e:
        logging.error(f"❌ Error in producer: {e}")
    finally:
        client.close()
        logging.info("🔴 Pulsar client closed.")

if __name__ == "__main__":
    produce_messages()
