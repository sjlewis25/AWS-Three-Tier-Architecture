#!/bin/bash
set -e  # Exit on any error

# Update and install dependencies
yum update -y
yum install -y python3-pip mysql git

# Install Python packages
pip3 install flask boto3 pymysql gunicorn

# Create app directory
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

# Write app.py
cat > app.py <<'EOF'
from flask import Flask, request, jsonify
import pymysql
import boto3
import json
import sys

app = Flask(__name__)

def get_db_config():
    try:
        client = boto3.client("secretsmanager", region_name="us-east-1")
        secret = client.get_secret_value(SecretId="rds_app_credentials")
        return json.loads(secret["SecretString"])
    except Exception as e:
        print(f"Error fetching secrets: {e}", file=sys.stderr)
        # Fallback to environment variables if Secrets Manager fails
        return {
            "DB_HOST": "${db_host}",
            "DB_USER": "${db_user}",
            "DB_PASS": "${db_password}",
            "DB_NAME": "mydb"
        }

secret = get_db_config()
DB_HOST = secret.get("DB_HOST")
DB_USER = secret.get("DB_USER")
DB_PASS = secret.get("DB_PASS")
DB_NAME = secret.get("DB_NAME", "mydb")

def get_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )

@app.route("/")
def index():
    return "Business Automation System is running."

@app.route("/health")
def health():
    return "healthy", 200

@app.route("/submit_order", methods=["POST"])
def submit_order():
    data = request.get_json()
    customer = data.get("customer")
    item = data.get("item")
    quantity = data.get("quantity")

    if not all([customer, item, quantity]):
        return jsonify({"error": "Missing required fields"}), 400

    try:
        conn = get_connection()
        with conn.cursor() as cursor:
            sql = "INSERT INTO orders (customer, item, quantity) VALUES (%s, %s, %s)"
            cursor.execute(sql, (customer, item, quantity))
        conn.commit()
        return jsonify({"message": "Order received", "data": data}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

# Wait for RDS to be fully available
echo "Waiting for RDS to be ready..."
sleep 60

# Create database and orders table if they don't exist
mysql -h "$(echo ${db_host} | cut -d: -f1)" -u "${db_user}" -p"${db_password}" <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS mydb;
USE mydb;
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer VARCHAR(255) NOT NULL,
    item VARCHAR(255) NOT NULL,
    quantity INT NOT NULL,
    order_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
MYSQL_SCRIPT

# Start Flask app with gunicorn on port 5000
cd /home/ec2-user/app
gunicorn -w 2 -b 0.0.0.0:5000 app:app --daemon --log-file /home/ec2-user/app/gunicorn.log

echo "Flask app started on port 5000"







