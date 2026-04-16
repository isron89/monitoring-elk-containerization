#!/bin/bash
# Kafka Console Producer Sample for LOCAL Kafka Server
# This script sends a test message to Kafka using kafka-console-producer

KAFKA_BROKER="localhost:9092"
TOPIC="${TOPIC:-mypertamina-dev}"  # Use env variable or default to mypertamina-dev

# Kafka installation path (update if your Kafka is installed elsewhere)
KAFKA_HOME="/Users/husseinisron/Documents/Aplikasi/kafka/kafka_2.13-4.1.1"

# The telemetry message (properly formatted as JSON)
MESSAGE='{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "tranTime": "2026-03-16T10:30:45.123Z",
  "executeTime": 125,
  "serverName": "example-service",
  "serverPort": 3000,
  "contextPath": "/api",
  "servletPath": "/users/123",
  "scheme": "http",
  "localAddr": "127.0.0.1",
  "reqMethod": "POST",
  "reqParams": "{}",
  "reqQueryParams": "page=1&limit=10",
  "reqContentLength": 256,
  "reqBody": "{\"username\":\"john.doe\",\"password\":\"xxxx\"}",
  "reqHeaders": {
    "content-type": "application/json",
    "user-agent": "Mozilla/5.0",
    "authorization": "Bearer xxxxxxxxxxxxx",
    "x-trace-id": "abc123def456",
    "x-span-id": "span789"
  },
  "clientIp": "192.168.1.100",
  "uri": "/api/users/123",
  "url": "http://localhost:3000/api/users/123?page=1&limit=10",
  "rawUri": "/api/users/123?page=1&limit=10",
  "respHttpStatus": 200,
  "respContentLength": 512,
  "respStatus": "OK",
  "respBody": "{\"success\":true,\"token\":\"xxxx\",\"user\":{\"id\":\"123\"}}",
  "respHeaders": {
    "content-type": "application/json",
    "x-trace-id": "abc123def456"
  },
  "traceId": "abc123def456",
  "spanId": "span789",
  "parentSpanId": "parentSpan456",
  "service": "example-service",
  "userId": "user123",
  "customerId": "cust456",
  "eventCode": "LOGIN_SUCCESS",
  "source": "REST",
  "requestId": "req-550e8400"
}'

echo "Sending message to Kafka topic: $TOPIC at $KAFKA_BROKER"
echo "================================================"

# Convert multiline JSON to single line (remove newlines and extra spaces)
MESSAGE_ONELINE=$(echo "$MESSAGE" | tr -d '\n' | tr -s ' ')

# Check if kafka-console-producer is in PATH
if command -v kafka-console-producer &> /dev/null; then
    # kafka-console-producer is in PATH
    echo "$MESSAGE_ONELINE" | kafka-console-producer \
      --bootstrap-server $KAFKA_BROKER \
      --topic $TOPIC
    
elif [ -f "$KAFKA_HOME/bin/kafka-console-producer.sh" ]; then
    # Use from KAFKA_HOME
    echo "$MESSAGE_ONELINE" | $KAFKA_HOME/bin/kafka-console-producer.sh \
      --bootstrap-server $KAFKA_BROKER \
      --topic $TOPIC
    
else
    echo "Error: kafka-console-producer not found!"
    echo ""
    echo "Please install Kafka or set KAFKA_HOME environment variable."
    echo "Example:"
    echo "  export KAFKA_HOME=/path/to/kafka"
    echo "  ./sample-kafka-send.sh"
    echo ""
    echo "Or install Kafka:"
    echo "  brew install kafka  (macOS)"
    exit 1
fi

echo ""
echo "✓ Message sent successfully to topic: $TOPIC"
echo ""
echo "To send to other topics, modify TOPIC variable:"
echo "  TOPIC=mypertamina-staging ./sample-kafka-send.sh"
echo "  TOPIC=mypertamina-prod ./sample-kafka-send.sh"
