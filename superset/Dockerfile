FROM apache/superset:latest
USER root
# Install the package directly into the Superset virtual environment's site-packages
RUN pip install duckdb-engine --target /app/.venv/lib/python3.10/site-packages/
USER superset
