param(
  [string]$EnvFile = ".env.prod"
)

$ErrorActionPreference = "Stop"

Write-Host "=== EduBridge Deploy PROD ===" -ForegroundColor Cyan

if (!(Test-Path $EnvFile)) {
  Write-Host "Fichier $EnvFile introuvable." -ForegroundColor Red
  Write-Host "Copie .env.prod.example -> .env.prod et remplis les valeurs." -ForegroundColor Yellow
  exit 1
}

Write-Host "1) Pull image Docker Hub..." -ForegroundColor Green
docker compose --env-file $EnvFile -f docker-compose.prod.yml pull

Write-Host "2) Lancement des conteneurs..." -ForegroundColor Green
docker compose --env-file $EnvFile -f docker-compose.prod.yml up -d

Write-Host "3) Statut..." -ForegroundColor Green
docker compose --env-file $EnvFile -f docker-compose.prod.yml ps

Write-Host "Déploiement terminé." -ForegroundColor Cyan
Write-Host "Teste: http://localhost:3000/api/health" -ForegroundColor Yellow

