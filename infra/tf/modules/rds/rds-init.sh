#!/bin/bash
set -e  # Exit on any error

# Check if all required arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 S3_BUCKET RDS_HOST DB_ADMIN_USER DB_ADMIN_PASS"
    exit 1
fi

S3_BUCKET=$1
RDS_HOST=$2
DB_ADMIN_USER=$3
DB_ADMIN_PASS=$4
DB_NAME="mydb"



sudo yum update -y 
sudo yum install -y mysql

sudo mkdir -p /tmp
sudo chmod 777 /tmp


sudo aws s3 cp s3://${S3_BUCKET}/init.sql /tmp/init.sql 

if ! mysql -h ${RDS_HOST} -u ${DB_ADMIN_USER} -P 3306 -p"${DB_ADMIN_PASS}" -e "SELECT 1;" > /dev/null 2>&1; then
    echo "Failed to connect to database"
    exit 1
fi

mysql -h ${RDS_HOST} -u ${DB_ADMIN_USER} -P 3306 -p"${DB_ADMIN_PASS}" <<EOF || { echo "Failed to create database"; exit 1; }
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
EOF

mysql -h ${RDS_HOST} -u ${DB_ADMIN_USER} -P 3306 -p"${DB_ADMIN_PASS}" ${DB_NAME} < /tmp/init.sql || { echo "Failed to import SQL file"; exit 1; }

echo "Script completed successfully"