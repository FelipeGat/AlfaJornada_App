#!/usr/bin/env bash
#
# Instala o keystore de release do AlfaMobi neste checkout. Rode isso UMA
# VEZ em cada máquina que vai fazer `flutter build apk --release` +
# publicar (ver scripts/publicar-update.sh).
#
# Uso:
#   scripts/instalar-keystore.sh <pasta-com-os-2-arquivos>
#
# A pasta precisa conter:
#   alfamobi-release.jks
#   keystore.properties
#
# Esses 2 arquivos NÃO ficam neste repositório (são credenciais — o .gitignore
# já bloqueia `android/alfamobi-release.jks` e `android/keystore.properties`
# por design). Peça pra quem já tem pra te passar por um canal privado
# (pen drive, AirDrop, etc.) — nunca por um canal público.
#
# O que faz:
#   1. Copia os 2 arquivos pra android/.
#   2. Confirma que o git está mesmo ignorando os dois.
#   3. Builda um APK de release de teste e confere a assinatura com
#      apksigner — se não bater com o fingerprint oficial, FALHA em vez de
#      deixar você publicar um APK assinado errado sem perceber (foi
#      exatamente isso que quebrou a atualização de todo mundo em
#      17/07/2026 — ver DEPLOY_PROTOCOLO.md).

set -euo pipefail

FINGERPRINT_ESPERADO="21f0c86d136f065be40b73603a23a915b3dd1adeed08727e56f88d135921d45c"

if [ $# -lt 1 ]; then
  echo "Uso: $0 <pasta-com-alfamobi-release.jks-e-keystore.properties>"
  exit 1
fi

ORIGEM="$1"
REPO_DIR="$(pwd)"

if [ ! -f "$REPO_DIR/pubspec.yaml" ] || ! grep -q "^name: alfa_mobile" "$REPO_DIR/pubspec.yaml" 2>/dev/null; then
  echo "❌ Rode este script a partir da raiz do repo alfa-mobile."
  exit 1
fi

if [ ! -f "$ORIGEM/alfamobi-release.jks" ] || [ ! -f "$ORIGEM/keystore.properties" ]; then
  echo "❌ Não encontrei alfamobi-release.jks e/ou keystore.properties em: $ORIGEM"
  exit 1
fi

echo "▸ Copiando keystore pra android/…"
cp "$ORIGEM/alfamobi-release.jks" "$REPO_DIR/android/alfamobi-release.jks"
cp "$ORIGEM/keystore.properties" "$REPO_DIR/android/keystore.properties"
echo "  OK"

echo
echo "▸ Confirmando que estão gitignored…"
if git check-ignore -q android/alfamobi-release.jks && git check-ignore -q android/keystore.properties; then
  echo "  OK — ambos ignorados pelo git"
else
  echo "  ⚠️  ATENÇÃO: pelo menos um dos arquivos NÃO está sendo ignorado."
  echo "     NÃO rode 'git add .' sem checar antes — isso vazaria a chave privada."
fi

echo
echo "▸ Buildando APK de release de teste pra validar a assinatura…"
flutter build apk --release

APK="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK" ]; then
  echo "❌ Build falhou — não gerou $APK"
  exit 1
fi

echo
echo "▸ Verificando assinatura…"
APKSIGNER=$(find "${ANDROID_HOME:-$HOME/Library/Android/sdk}/build-tools" -iname "apksigner*" -type f 2>/dev/null | sort -V | tail -1)
if [ -z "$APKSIGNER" ]; then
  echo "⚠️  apksigner não encontrado automaticamente. Rode manualmente:"
  echo "    apksigner verify --print-certs $APK"
  echo "  E confira se o SHA-256 bate com: $FINGERPRINT_ESPERADO"
  exit 0
fi

SAIDA=$("$APKSIGNER" verify --print-certs "$APK" 2>&1) || true
echo "$SAIDA"

if echo "$SAIDA" | grep -qi "Android Debug"; then
  echo
  echo "❌ FALHOU: o APK saiu assinado com o certificado de DEBUG, não o de release."
  echo "   Confira o campo 'storeFile' dentro de keystore.properties — deve ser"
  echo "   '../alfamobi-release.jks' (relativo a android/)."
  exit 1
fi

FINGERPRINT_ENCONTRADO=$(echo "$SAIDA" | grep "SHA-256" | head -1 | awk '{print $NF}' | tr 'A-F' 'a-f')
if [ "$FINGERPRINT_ENCONTRADO" != "$FINGERPRINT_ESPERADO" ]; then
  echo
  echo "❌ FALHOU: a assinatura não bate com o certificado oficial esperado."
  echo "   Esperado:   $FINGERPRINT_ESPERADO"
  echo "   Encontrado: $FINGERPRINT_ENCONTRADO"
  exit 1
fi

echo
echo "✅ Keystore instalado e validado — o certificado bate com o oficial."
echo "   'flutter build apk --release' nesta máquina agora sai assinado"
echo "   corretamente. Pode publicar normalmente com scripts/publicar-update.sh."
