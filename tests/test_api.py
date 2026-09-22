"""Tests minimaux de l'API. Lancement : ./outils/tester.sh"""
import pytest

from app import create_app

JETON_TEST = "jeton-de-test-fictif"


@pytest.fixture
def client(tmp_path):
    app = create_app(
        {
            "TESTING": True,
            "DATABASE": str(tmp_path / "test.db"),
            "API_TOKEN": JETON_TEST,
            "CHARGER_EXEMPLES": False,
        }
    )
    return app.test_client()


def creer(client, titre, contenu=""):
    return client.post(
        "/notes",
        json={"titre": titre, "contenu": contenu},
        headers={"X-Nimbus-Token": JETON_TEST},
    )


def test_health(client):
    reponse = client.get("/health")
    assert reponse.status_code == 200
    assert reponse.get_json() == {"status": "ok"}


def test_creer_et_lister(client):
    assert creer(client, "Ma note", "Bonjour").status_code == 201
    notes = client.get("/notes").get_json()
    assert len(notes) == 1
    assert notes[0]["titre"] == "Ma note"


def test_creer_sans_jeton_refuse(client):
    reponse = client.post("/notes", json={"titre": "Sans jeton"})
    assert reponse.status_code == 401


def test_rechercher(client):
    creer(client, "Courses")
    creer(client, "Réunion audit")
    resultat = client.get("/notes/search?q=audit").get_json()
    assert [n["titre"] for n in resultat] == ["Réunion audit"]
