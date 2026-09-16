"""Les routes de l'API : lister, créer et rechercher des notes."""
from flask import Blueprint, current_app, jsonify, request

from app.db import get_db

bp = Blueprint("notes", __name__)


@bp.get("/notes")
def lister_notes():
    lignes = get_db().execute("SELECT id, titre, contenu FROM notes ORDER BY id").fetchall()
    return jsonify([dict(ligne) for ligne in lignes])


@bp.post("/notes")
def creer_note():
    # Seuls les clients qui connaissent le jeton peuvent écrire
    if request.headers.get("X-Nimbus-Token") != current_app.config["API_TOKEN"]:
        return jsonify(erreur="jeton invalide"), 401

    donnees = request.get_json(silent=True) or {}
    if not donnees.get("titre"):
        return jsonify(erreur="le titre est obligatoire"), 400

    db = get_db()
    curseur = db.execute(
        "INSERT INTO notes (titre, contenu) VALUES (?, ?)",
        (donnees["titre"], donnees.get("contenu", "")),
    )
    db.commit()
    return jsonify(id=curseur.lastrowid, titre=donnees["titre"]), 201
