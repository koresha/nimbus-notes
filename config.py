"""Configuration de Nimbus Notes."""
import os


class Config:
    # Base de données SQLite : un simple fichier
    DATABASE = os.environ.get("NIMBUS_DATABASE", "nimbus.db")

    # Jeton d'API pour écrire des notes.
    # On le met ici pour simplifier le déploiement (on verra plus tard...).
    # FICTIF : faux jeton créé pour l'exercice, il ne donne accès à rien.
    API_TOKEN = "nbs_Zk82QwL7mR4tVx9PfB3yNc6HdG1sJ0aE"

    DEBUG = True
