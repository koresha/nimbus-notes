"""Nimbus Notes : une petite API de prise de notes."""
from flask import Flask, jsonify

from app import db, notes
from config import Config


def create_app(surcharge=None):
    """Crée l'application. `surcharge` permet de changer la config (tests)."""
    app = Flask(__name__)
    app.config.from_object(Config)
    if surcharge:
        app.config.update(surcharge)

    db.init_app(app)
    app.register_blueprint(notes.bp)

    @app.get("/health")
    def health():
        # Route de santé : sert aux contrôles automatiques (conteneur, supervision)
        return jsonify(status="ok")

    return app
