# Kafka Configuration for Docker Integration

## Problem
Your Kafka server is advertising itself as localhost:9092, which doesn't work from inside Docker containers.

## Solution

### If Kafka is Running Directly on Your Mac (not in Docker):

1. Find your Kafka configuration file (usually `server.properties` or `config/kraft/server.properties`)

2. Update the advertised listeners:
   ```properties
   # Allow both local and Docker container access
   listeners=PLAINTEXT://0.0.0.0:9092
   advertised.listeners=PLAINTEXT://host.docker.internal:9092
   ```

3. Restart your Kafka server

### If Kafka is Running in Docker:

Add this to your Kafka docker-compose.yml:
```yaml
environment:
  KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://host.docker.internal:9092
  KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
```

## Verification

After restarting Kafka, your Logstash container should connect successfully.
Check with:
```bash
docker logs logstash 2>&1 | tail -20
```

You should see successful coordinator discovery and partition assignment.
