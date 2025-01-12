from flask import Flask, render_template, request, Response
from os import environ
from dbcontext import db_data, db_delete, db_add, health_check
from person import Person
import logging

app = Flask(__name__)
app.logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
handler.setLevel(logging.INFO)
app.logger.addHandler(handler)

host_name = environ.get("HOSTNAME")
db_host = environ.get('DB_HOST')
backend = environ.get('BACKEND') or "http://localhost"

@app.route("/")
def main():
    app.logger.info("Entering main route")
    if not health_check():
        global host_name
        host_name = "no_host"
    data = db_data()
    return render_template("index.html.jinja", host_name=host_name, db_host=db_host, data=data, backend=backend)

@app.route("/delete/<int:id>", methods=["DELETE"])
def delete(id: int):
    app.logger.info("Request to delete person with id: %s", id)
    return db_delete(id)

@app.route("/add", methods=["PUT"])
def add():
    try:
        body = request.json
        if body is not None:
            app.logger.info("Request to add person with body: %s", body)
            # Create person with correct parameter order matching the frontend
            person = Person(0, 
                          body["firstName"], 
                          body["lastName"], 
                          int(body["age"]), # Ensure age is an integer
                          body["address"],
                          body["workplace"])
            return db_add(person)
        app.logger.error("Request body is empty")
        return Response(status=400)  # Changed from 404 to 400 for bad request
    except KeyError as e:
        app.logger.error(f"Missing required field: {str(e)}")
        return Response(status=400)
    except ValueError as e:
        app.logger.error(f"Invalid data format: {str(e)}")
        return Response(status=400)
    except Exception as e:
        app.logger.error(f"Error processing request: {str(e)}")
        return Response(status=500)

@app.route("/health")
def health():
    if health_check():  
        app.logger.info("Health check passed")
        return Response(status=200)
    app.logger.error("Health check failed")
    return Response(status=503)

@app.route("/ready")
def ready():
    if health_check() and app.debug:  
        return Response(status=200)