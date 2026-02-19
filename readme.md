# KKW Monitoring System

A real-time telemetry monitoring solution built for Pertamina PPN OJT/KKW operations using the ELK Stack (Elasticsearch, Logstash, Kibana) integrated with your external Apache Kafka server for streaming data ingestion.

## Purpose

This monitoring system collects, processes, and visualizes telemetry data from operational systems, enabling real-time performance tracking and analysis. It identifies slow requests (execution time > 3000ms) and stores time-series data for historical analysis.

## Architecture Components

### Data Streaming Layer
- **Apache Kafka** (External): Message broker for reliable telemetry data ingestion - connects to your own Kafka server

### Data Processing Layer
- **Logstash**: Consumes telemetry messages from Kafka topic `telemetry-topic`, performs data transformation, filters invalid records, and enriches slow request markers

### Storage Layer
- **Elasticsearch** (Port 9200): Time-series database with daily indices (`telemetry-YYYY.MM.dd`) for efficient data storage and retrieval

### Visualization Layer
- **Kibana** (Port 5601): Web-based dashboard for data visualization and analysis

## Key Features

- Real-time telemetry data processing from external Kafka streams
- Automatic slow request detection (>3s execution time)
- ISO8601 timestamp normalization
- Daily indexed data storage for efficient querying
- Persistent data volumes for Elasticsearch
- Health checks and automatic service restart
- Secured Elasticsearch with authentication (elastic/pertamina)
- Flexible Kafka server configuration via environment variables

## Data Flow

1. Telemetry data published to your external Kafka server (`telemetry-topic`)
2. Logstash consumes messages and validates required fields (tranTime)
3. Filters and enriches data (marks slow requests)
4. Stores processed data in Elasticsearch daily indices
5. Kibana provides visualization and querying interface

## Getting Started

### Prerequisites
- Docker and Docker Compose installed
- Access to an external Kafka server

### Configuration

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file and configure your Kafka server:
   ```bash
   KAFKA_BOOTSTRAP_SERVERS=your-kafka-server:9092
   ```

   For multiple brokers, use comma-separated values:
   ```bash
   KAFKA_BOOTSTRAP_SERVERS=kafka1:9092,kafka2:9092,kafka3:9092
   ```

### Start All Services
```bash
docker-compose up -d
```

### Ensure Kafka Topic Exists

Make sure the `telemetry-topic` exists on your Kafka server. If not, create it using your Kafka admin tools:
```bash
kafka-topics --create --topic telemetry-topic --bootstrap-server your-kafka-server:9092 --partitions 1 --replication-factor 1
```

### Test the Pipeline

Produce a test message to your Kafka server:
```bash
kafka-console-producer --topic telemetry-topic --bootstrap-server your-kafka-server:9092
```

Then paste a JSON message:
```json
{"tranTime":"2024-02-15T10:00:00Z","executeTime":1500,"message":"test"}
```

### Access Services

- **Elasticsearch**: http://127.0.0.1:9200 (elastic/pertamina)
- **Kibana**: http://127.0.0.1:5601

## Monitoring

Check service logs:
```bash
docker-compose logs -f [service-name]
```

View all running services:
```bash
docker-compose ps
```

Check Logstash is consuming from Kafka:
```bash
docker-compose logs -f logstash
```

## Security Configuration (Optional)

If your Kafka server requires authentication, uncomment and configure the security settings in `logstash.conf`:

```conf
security_protocol => "SASL_SSL"
sasl_mechanism => "PLAIN"
sasl_jaas_config => "org.apache.kafka.common.security.plain.PlainLoginModule required username='user' password='pass';"
```

## Technical Details

This containerized solution provides a complete monitoring infrastructure for tracking application performance metrics and telemetry data, designed to integrate seamlessly with your existing Kafka infrastructure.

## Troubleshooting

**Logstash can't connect to Kafka:**
- Verify the `KAFKA_BOOTSTRAP_SERVERS` value in your `.env` file
- Ensure your Kafka server is accessible from the Docker network
- Check network connectivity: `docker exec logstash ping your-kafka-server`

**No data appearing in Elasticsearch:**
- Verify the `telemetry-topic` exists on your Kafka server
- Check Logstash logs for errors: `docker-compose logs logstash`
- Ensure messages in Kafka have the required `tranTime` field
