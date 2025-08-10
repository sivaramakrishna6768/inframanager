from flask import Flask, jsonify
import socket

app = Flask(__name__)

@app.get("/")
def index():
    host = socket.gethostname()
    return f"""
    <html>
      <head><title>InfraManager</title></head>
      <body style="font-family: sans-serif;">
        <h1>InfraManager – Flask</h1>
        <p>Container running on host: <b>{host}</b></p>
        <p>Try <a href="/healthz">/healthz</a> for a health check.</p>
      </body>
    </html>
    """

@app.get("/healthz")
def healthz():
    return jsonify(status="ok", host=socket.gethostname())
