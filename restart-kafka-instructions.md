# Restart Kafka Instructions

## Step 1: Stop Kafka

Find the Kafka process and stop it:
```bash
# Find Kafka process ID
ps aux | grep kafka | grep server.properties | grep -v grep

# Kill the Kafka process (replace PID with actual process ID)
kill <PID>

# Or use pkill (be careful, this kills all Kafka processes)
pkill -f kafka
```

## Step 2: Start Kafka

Navigate to your Kafka directory and start it:
```bash
cd /Users/husseinisron/Documents/Aplikasi/kafka/kafka_2.13-4.1.1

# Start Kafka in the background
nohup bin/kafka-server-start.sh config/server.properties > logs/kafka.log 2>&1 &

# Or start in foreground (you'll see the logs)
bin/kafka-server-start.sh config/server.properties
```

## Step 3: Verify Kafka is Running

```bash
# Check if Kafka is listening on port 9092
lsof -i :9092

# Check recent logs
tail -f /Users/husseinisron/Documents/Aplikasi/kafka/kafka_2.13-4.1.1/logs/server.log
```

## Step 4: Restart Logstash

After Kafka is running with the new configuration:
```bash
cd "/Users/husseinisron/Documents/Work/Pertamina/PPN OJT/OJT/KKW/Monitoring"
docker-compose restart logstash
```

## Step 5: Verify Connection

Check Logstash logs to verify successful connection:
```bash
docker logs logstash 2>&1 | tail -30
```

You should see messages like:
- "Successfully joined group"
- "Partition assignment completed"
- No more "could not be established" errors

## Configuration Change Made:
Changed in `/Users/husseinisron/Documents/Aplikasi/kafka/kafka_2.13-4.1.1/config/server.properties`:
```
advertised.listeners=PLAINTEXT://host.docker.internal:9092,CONTROLLER://localhost:9093
```

This allows Docker containers to connect to Kafka using `host.docker.internal`.
