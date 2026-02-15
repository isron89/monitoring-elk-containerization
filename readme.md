# ELK Monitoring System

A real-time telemetry monitoring solution using the ELK Stack (Elasticsearch, Logstash, Kibana) integrated with Apache Kafka for streaming data ingestion.

## Purpose

This monitoring system collects, processes, and visualizes telemetry data from operational systems, enabling real-time performance tracking and analysis. It identifies slow requests (execution time > 3000ms) and stores time-series data for historical analysis.

## Architecture Components

### Data Streaming Layer
- **Apache Kafka** (Ports 9092/9093): Message broker for reliable telemetry data ingestion
- **Zookeeper** (Port 2181): Manages Kafka cluster coordination

### Data Processing Layer
- **Logstash**: Consumes telemetry messages from Kafka topic `telemetry-topic`, performs data transformation, filters invalid records, and enriches slow request markers

### Storage Layer
- **Elasticsearch** (Port 9200): Time-series database with daily indices (`telemetry-YYYY.MM.dd`) for efficient data storage and retrieval

### Visualization Layer
- **Kibana** (Port 5601): Web-based dashboard for data visualization and analysis

## Key Features

- Real-time telemetry data processing from Kafka streams
- Automatic slow request detection (>3s execution time)
- ISO8601 timestamp normalization
- Daily indexed data storage for efficient querying
- Persistent data volumes for all services
- Health checks and automatic service restart
- Secured Elasticsearch with authentication (elastic/password)

## Data Flow

1. Telemetry data published to Kafka `telemetry-topic`
2. Logstash consumes messages and validates required fields (tranTime)
3. Filters and enriches data (marks slow requests)
4. Stores processed data in Elasticsearch daily indices
5. Kibana provides visualization and querying interface

## Getting Started

### Prerequisites
- Docker and Docker Compose installed

### Start All Services
```bash
docker-compose up -d
```

### Create the Telemetry Topic
If not auto-created:
```bash
docker exec -it kafka kafka-topics --create --topic telemetry-topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
```

### Test the Pipeline
Produce a test message:
```bash
docker exec -it kafka kafka-console-producer --topic telemetry-topic --bootstrap-server localhost:9092
```

Then paste a JSON message:
```json
{"tranTime":"2024-02-15T10:00:00Z","executeTime":1500,"message":"test"}
```

### Access Services

- **Kafka**: localhost:9093
- **Elasticsearch**: http://localhost:9200 (elastic/password)
- **Kibana**: http://localhost:5601

## Monitoring

Check service logs:
```bash
docker-compose logs -f [service-name]
```

View all running services:
```bash
docker-compose ps
```

## Technical Details

This containerized solution provides a complete, production-ready monitoring infrastructure for tracking application performance metrics and telemetry data.