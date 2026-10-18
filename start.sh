#!/bin/bash
PORT=${PORT:-8080}
echo "Starting Uvicorn on port $PORT"
exec uvicorn app:app --host 0.0.0.0 --port $PORT --workers 1
