from flask import Flask, render_template, url_for, request
from prometheus_flask_exporter import PrometheusMetrics


app.register_error_handler(400, handle_bad_request)
def handle_bad_request(e):
    return 'bad request!', 400