#!/usr/bin/env bash
# Corre todas las pruebas con cobertura y genera un reporte HTML navegable.
# Uso: bash scripts/test_coverage.sh
set -e

echo "Ejecutando pruebas con cobertura..."
flutter test --coverage

# genhtml viene del paquete "lcov" (Linux: apt install lcov,
# Mac: brew install lcov). Si no lo tienes instalado, el archivo
# coverage/lcov.info ya sirve para subir a Codecov/Coveralls en CI.
if command -v genhtml &> /dev/null; then
  genhtml coverage/lcov.info -o coverage/html
  echo "Reporte generado en coverage/html/index.html"
else
  echo "genhtml no está instalado — el reporte crudo quedó en coverage/lcov.info"
  echo "Instálalo con: sudo apt install lcov   (o) brew install lcov"
fi
