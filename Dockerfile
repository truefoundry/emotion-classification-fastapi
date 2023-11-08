FROM --platform=linux/amd64 python:3.10-slim
COPY requirements.txt /tmp/requirements.txt
RUN pip install -U pip setuptools wheel && pip install -r /tmp/requirements.txt
EXPOSE 8000
WORKDIR /app
COPY . /app/
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
