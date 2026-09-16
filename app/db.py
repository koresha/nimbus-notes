"""Accès à la base SQLite (un simple fichier)."""
import sqlite3

import yaml
from flask import current_app, g

SCHEMA = """
CREATE TABLE IF NOT EXISTS notes (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    titre   TEXT NOT NULL,
    contenu TEXT NOT NULL DEFAULT ''
)
"""


def get_db():
    """Ouvre la connexion à la base (une par requête)."""
    if "db" not in g:
        g.db = sqlite3.connect(current_app.config["DATABASE"])
        g.db.row_factory = sqlite3.Row
    return g.db


def close_db(erreur=None):
    connexion = g.pop("db", None)
    if connexion is not None:
        connexion.close()


def init_app(app):
    """Crée la table au démarrage et charge quelques notes d'exemple."""
    app.teardown_appcontext(close_db)
    with app.app_context():
        connexion = get_db()
        connexion.execute(SCHEMA)
        vide = connexion.execute("SELECT COUNT(*) FROM notes").fetchone()[0] == 0
        if vide and app.config.get("CHARGER_EXEMPLES", True):
            with open("data/notes-exemple.yaml", encoding="utf-8") as fichier:
                for note in yaml.safe_load(fichier):
                    connexion.execute(
                        "INSERT INTO notes (titre, contenu) VALUES (?, ?)",
                        (note["titre"], note["contenu"]),
                    )
        connexion.commit()
