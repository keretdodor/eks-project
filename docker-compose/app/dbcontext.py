import mysql.connector
from os import environ
from person import Person
from flask import Response
import logging

logger = logging.getLogger(__name__)

db_user = environ.get('DB_USER')
db_pass = environ.get('DB_PASS')
db_host = environ.get('DB_HOST')
db_name = environ.get('DB_NAME')

config = {
    "host": db_host,
    "user": db_user,
    "password": db_pass,
    "database": db_name,
    "port": 3306
}

def demo_data() -> list[Person]:
    person1 = Person(1, "John", "Doe", 30, "76 Ninth Avenue St, New York, NY 10011, USA", "Google")
    person2 = Person(2, "Jane", "Doe", 28, "15 Aabogade St, Aarhus, Denmark 8200", "Microsoft")
    person3 = Person(3, "Jack", "Doe", 25, "98 Yigal Alon St, Tel Aviv, Israel 6789141", "Amazon")
    return [person1, person2, person3]

def get_connection():
    if not db_host:
        return None
    
    if not (db_user and db_pass):
        raise Exception("DB_USER and DB_PASS are not set")
    
    try:
        return mysql.connector.connect(**config)
    except mysql.connector.Error as e:
        logger.error(f"Database connection failed: {e}")
        return None

def db_data() -> list[Person]:
    if not db_host:
        return demo_data()
    
    cnx = get_connection()
    if not cnx:
        return demo_data()
    
    result = []
    cursor = cnx.cursor()
    try:
        cursor.execute("SELECT * FROM people")
        for item in cursor:
            result.append(Person(item[0], item[1], item[2], item[3], item[4], item[5]))
        return result
    except mysql.connector.Error as e:
        logger.error(f"Error fetching data: {e}")
        return demo_data()
    finally:
        cursor.close()
        cnx.close()

def db_delete(id: int) -> Response:
    if not db_host:
        return Response(status=200)
    
    cnx = get_connection()
    if not cnx:
        return Response(status=503)
    
    cursor = cnx.cursor()
    try:
        cursor.execute("DELETE FROM people WHERE id = %s", (id,))
        cnx.commit()
        if cursor.rowcount == 0:
            return Response(status=404)  # Not found
        return Response(status=200)
    except mysql.connector.Error as e:
        logger.error(f"Error deleting person {id}: {e}")
        return Response(status=500)
    finally:
        cursor.close()
        cnx.close()

def db_add(person: Person) -> Response:
    if not db_host:
        return Response(status=200)
    
    cnx = get_connection()
    if not cnx:
        return Response(status=503)
    
    cursor = cnx.cursor()
    try:
        sql = """INSERT INTO people 
                (firstname, lastname, age, address, workplace) 
                VALUES (%s, %s, %s, %s, %s)"""
        values = (person.first_name, person.last_name, person.age, 
                 person.address, person.workplace)
        cursor.execute(sql, values)
        cnx.commit()
        return Response(status=200, response=str(cursor.lastrowid))
    except mysql.connector.Error as e:
        logger.error(f"Error adding person: {e}")
        return Response(status=500)
    finally:
        cursor.close()
        cnx.close()

def health_check() -> bool:
    if not db_host:
        return True
    
    cnx = get_connection()
    if not cnx:
        return False
    
    cursor = cnx.cursor()
    try:
        cursor.execute("SELECT 1")
        cursor.fetchall()
        return True
    except mysql.connector.Error as e:
        logger.error(f"Health check failed: {e}")
        return False
    finally:
        cursor.close()
        cnx.close()