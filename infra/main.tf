# Infrastructure AWS de Nimbus Notes (exercice : ce code n'est JAMAIS appliqué).

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

# --- Stockage des sauvegardes ---------------------------------------------

resource "aws_s3_bucket" "sauvegardes" {
  bucket = "nimbus-notes-sauvegardes"
}

resource "aws_s3_bucket_ownership_controls" "sauvegardes" {
  bucket = aws_s3_bucket.sauvegardes.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# On l'ouvre à tout le monde pour que le client puisse télécharger les exports
resource "aws_s3_bucket_acl" "sauvegardes" {
  depends_on = [aws_s3_bucket_ownership_controls.sauvegardes]

  bucket = aws_s3_bucket.sauvegardes.id
  acl    = "public-read"
}

# --- Réseau : accès au serveur --------------------------------------------

data "aws_vpc" "defaut" {
  default = true
}

resource "aws_security_group" "api" {
  name   = "nimbus-notes-api"
  vpc_id = data.aws_vpc.defaut.id

  ingress {
    description = "SSH administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "API"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Base de données --------------------------------------------------------

resource "aws_db_instance" "notes" {
  identifier        = "nimbus-notes"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  username = "nimbus"
  # FICTIF : mot de passe d'exercice, écrit en dur dans le code
  password = "Nbs-Db-7rT4xQ9mLw2Zs"

  publicly_accessible    = true
  storage_encrypted      = false
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.api.id]
}
