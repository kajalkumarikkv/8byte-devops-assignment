FROM python:3.12-slim

RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY app/ .

EXPOSE 8081

CMD ["python", "app.py"]
