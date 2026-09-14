"""Configuration de Nimbus Notes."""
import os


class Config:
    # Base de données SQLite : un simple fichier
    DATABASE = os.environ.get("NIMBUS_DATABASE", "nimbus.db")

    # Jeton d'API pour écrire des notes (à définir dans l'environnement)
    API_TOKEN = os.environ.get("NIMBUS_API_TOKEN", "")

    DEBUG = True
