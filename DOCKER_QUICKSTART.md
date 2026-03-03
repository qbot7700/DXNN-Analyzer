# Docker Quick Start Guide

## Prerequisites

- Docker Desktop installed and running
- Docker Compose (included with Docker Desktop)

## Quick Start

### Build the Image

```bash
docker-compose build
```

This takes 5-10 minutes the first time.

### Start the Container

```bash
docker-compose up -d
```

Subsequent starts are instant.

### Access the Application

Open your browser to: **http://localhost:4000**

## What's Included

The container includes:
- Complete DXNN Analyzer (Erlang backend)
- Phoenix LiveView web interface
- Sample databases from `./Databases` folder
- All dependencies pre-installed

Everything runs independently inside the container.

## Usage

### Load a Context

The container includes the sample databases. To load one:

1. Navigate to Dashboard
2. Enter Mnesia path: `./Databases/Mnesia.nonode@nohost`
3. Enter context name: `exp1`
4. Click "Load Context"

### Using External Databases

To use databases from outside the container, edit `docker-compose.yml`:

```yaml
volumes:
  - /path/to/your/databases:/app/external_databases:ro
  - dxnn_data:/app/data
```

Then use path `/app/external_databases/Mnesia.nonode@nohost` in the web interface.

## Container Management

### View Logs

```bash
docker-compose logs -f
```

### Stop the Application

```bash
docker-compose down
```

### Restart Container

```bash
docker-compose restart
```

### Rebuild After Code Changes

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Data Persistence

The master database is stored in a Docker volume named `dxnn_data`. This persists even when the container is removed.

### Backup Master Database

```bash
docker-compose exec dxnn_analyzer_web tar czf /tmp/master_backup.tar.gz /app/data/MasterDatabase
docker cp $(docker-compose ps -q dxnn_analyzer_web):/tmp/master_backup.tar.gz ./master_backup.tar.gz
```

### View Volume Data

```bash
docker volume inspect dxnn_data
```

### Remove All Data (including volumes)

```bash
docker-compose down -v
```

## Troubleshooting

### Port Already in Use

Change the port in `docker-compose.yml`:

```yaml
ports:
  - "4001:4000"  # Use port 4001 instead
```

### Container Won't Start

```bash
docker-compose logs dxnn_analyzer_web
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Access Container Shell

```bash
docker-compose exec dxnn_analyzer_web sh
```
