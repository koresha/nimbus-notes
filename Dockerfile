# Image de l'API Nimbus Notes
FROM python:3.9.18-slim

WORKDIR /app
COPY . .

# Jeton d'API pour le conteneur (FICTIF - exercice pédagogique)
ENV NIMBUS_API_TOKEN=nbs_Zk82QwL7mR4tVx9PfB3yNc6HdG1sJ0aE

RUN pip install -r requirements.txt

EXPOSE 5000
CMD ["python", "run.py"]
