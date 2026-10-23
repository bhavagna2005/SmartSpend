
FROM python:3.12-slim

WORKDIR /app

COPY backend/requirements.txt .

RUN pip install --no-cache-dir --default-timeout=300 --retries=10 -r requirements.txt

COPY backend/ .

EXPOSE 5000

CMD ["python", "app.py"]

