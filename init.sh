#!/usr/bin/env bash
# init.sh — Instala workflow-ia-web en un proyecto existente sin pisar nada.
#
# Uso (desde la raíz de tu proyecto):
#   curl -fsSL https://raw.githubusercontent.com/OWNER/workflow-ia-web/main/init.sh | bash
#
# O descargado localmente:
#   bash init.sh [--dry-run]
#
# Variables de entorno:
#   GITHUB_TOKEN  → token de GitHub para repos privados o evitar rate limit
#   DRY_RUN=1     → equivalente a --dry-run

set -euo pipefail

# ─── Configuración ────────────────────────────────────────────────────────────

WORKFLOW_REPO="sonofgod1/workflow-ia-web"   # ← Reemplazar con tu usuario/org de GitHub
BRANCH="main"
GITHUB_API="https://api.github.com"
RAW_BASE="https://raw.githubusercontent.com/$WORKFLOW_REPO/$BRANCH"

# ─── Flags ────────────────────────────────────────────────────────────────────

DRY_RUN=false
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done
[[ "${DRY_RUN_ENV:-0}" == "1" ]] && DRY_RUN=true

# ─── Colores ──────────────────────────────────────────────────────────────────

C_RED=$'\033[0;31m'
C_GREEN=$'\033[0;32m'
C_YELLOW=$'\033[0;33m'
C_BLUE=$'\033[0;34m'
C_BOLD=$'\033[1m'
C_RESET=$'\033[0m'

ok()   { echo "  ${C_GREEN}✓${C_RESET}  $*"; }
warn() { echo "  ${C_YELLOW}⚠${C_RESET}  $*"; }
err()  { echo "  ${C_RED}✗${C_RESET}  $*" >&2; exit 1; }
info() { echo "  ${C_BLUE}ℹ${C_RESET}  $*"; }
step() { echo ""; echo "${C_BOLD}── $* ──────────────────────────────────────────────${C_RESET}"; }

# ─── Verificar dependencias ───────────────────────────────────────────────────

command -v curl > /dev/null 2>&1 || err "curl es necesario. Instálalo antes de continuar."
command -v git  > /dev/null 2>&1 || err "git es necesario. Instálalo antes de continuar."

# ─── Banner ───────────────────────────────────────────────────────────────────

echo ""
echo "${C_BOLD}┌──────────────────────────────────────────────────────┐${C_RESET}"
echo "${C_BOLD}│         workflow-ia-web — instalador                 │${C_RESET}"
echo "${C_BOLD}└──────────────────────────────────────────────────────┘${C_RESET}"
echo ""
info "Repositorio fuente : $WORKFLOW_REPO@$BRANCH"
$DRY_RUN && echo "  ${C_YELLOW}[dry-run]${C_RESET} No se escribirá ningún archivo."
echo ""

# ─── 1. Verificar / inicializar Git ───────────────────────────────────────────

step "Verificando repositorio Git"

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  warn "No hay repositorio Git aquí."
  printf "  ¿Deseas inicializarlo ahora? (s/n): "
  read -r INIT_GIT
  if [[ "$INIT_GIT" =~ ^[sS] ]]; then
    $DRY_RUN || git init
    ok "Repositorio Git inicializado"
  else
    err "Este instalador necesita un repositorio Git. Ejecuta 'git init' primero."
  fi
else
  ok "Repositorio Git encontrado: $(git rev-parse --show-toplevel)"
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel)
cd "$PROJECT_ROOT"

# ─── 2. Detectar tipo de proyecto web ─────────────────────────────────────────

step "Detectando stack web"

declare -a DETECTED=()

# Frameworks JS/TS
[ -f "next.config.js" ]  || [ -f "next.config.ts" ]  || [ -f "next.config.mjs" ] && DETECTED+=("Next.js")
[ -f "nuxt.config.ts" ]  || [ -f "nuxt.config.js" ]  && DETECTED+=("Nuxt")
[ -f "astro.config.mjs" ] || [ -f "astro.config.ts" ] && DETECTED+=("Astro")
[ -f "svelte.config.js" ] && DETECTED+=("SvelteKit")
[ -f "remix.config.js" ]  && DETECTED+=("Remix")
[ -f "gatsby-config.js" ] || [ -f "gatsby-config.ts" ] && DETECTED+=("Gatsby")
[ -f "vite.config.js" ]  || [ -f "vite.config.ts" ] && DETECTED+=("Vite")
[ -f "angular.json" ] && DETECTED+=("Angular")

# CMS y plataformas
[ -f "sanity.config.ts" ] || [ -f "sanity.config.js" ] && DETECTED+=("Sanity CMS")
[ -f "contentlayer.config.ts" ] && DETECTED+=("Contentlayer")
[ -f "payload.config.ts" ] && DETECTED+=("Payload CMS")
[ -f "wp-config.php" ] && DETECTED+=("WordPress")

# Build y package
[ -f "package.json" ]     && DETECTED+=("Node.js / npm")
[ -f "pnpm-lock.yaml" ]   && DETECTED+=("pnpm")
[ -f "bun.lockb" ]        && DETECTED+=("Bun")
[ -f "tsconfig.json" ]    && DETECTED+=("TypeScript")
[ -f "tailwind.config.js" ] || [ -f "tailwind.config.ts" ] && DETECTED+=("Tailwind CSS")
[ -f "postcss.config.js" ] && DETECTED+=("PostCSS")

# Hosting / deploy
[ -f "vercel.json" ]      && DETECTED+=("Vercel (config detectada)")
[ -f "netlify.toml" ]     && DETECTED+=("Netlify (config detectada)")
[ -f "Dockerfile" ]       && DETECTED+=("Docker")
[ -f ".github/workflows" ] && DETECTED+=("GitHub Actions")

if [ ${#DETECTED[@]} -eq 0 ]; then
  warn "No se detectó stack obvio. El agente lo descubrirá en /discovery o /architect."
else
  for item in "${DETECTED[@]}"; do
    ok "$item"
  done
  info "Stack registrado — /architect lo formalizará en ADRs."
fi

# ─── 3. Verificar conflictos ──────────────────────────────────────────────────

step "Verificando conflictos"

CLAUDE_EXISTS=false
COMMANDS_EXIST=false

if [ -f "CLAUDE.md" ]; then
  CLAUDE_EXISTS=true
  warn "CLAUDE.md ya existe → se preservará sin modificar."
fi

if [ -d ".claude/commands" ] && [ "$(ls -A .claude/commands 2>/dev/null)" ]; then
  COMMANDS_EXIST=true
  warn ".claude/commands ya contiene archivos."
  echo ""
  printf "  ¿Sobreescribir los comandos existentes? (s/n): "
  read -r OVERWRITE
  if [[ ! "$OVERWRITE" =~ ^[sS] ]]; then
    info "Instalación cancelada."
    info "Usa sync-workflow.sh para actualizar comandos sin tocar CLAUDE.md."
    exit 0
  fi
fi

# ─── 4. Conectar con GitHub y obtener árbol de archivos ───────────────────────

step "Conectando con GitHub"

API_HEADERS=(-H "Accept: application/vnd.github.v3+json")
if [ -n "${GITHUB_TOKEN:-}" ]; then
  API_HEADERS+=(-H "Authorization: token $GITHUB_TOKEN")
  info "Usando GITHUB_TOKEN"
fi

TREE_URL="$GITHUB_API/repos/$WORKFLOW_REPO/git/trees/$BRANCH?recursive=1"
TREE_RESPONSE=$(curl -s "${API_HEADERS[@]}" "$TREE_URL" 2>/dev/null)

if echo "$TREE_RESPONSE" | grep -q '"message"'; then
  API_MSG=$(echo "$TREE_RESPONSE" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
  err "Error de GitHub API: $API_MSG

  Posibles causas:
  • Repositorio aún no publicado en GitHub
  • WORKFLOW_REPO incorrecto en este script
  • Rate limit de GitHub (exporta GITHUB_TOKEN para evitarlo)

  Verifica el valor de WORKFLOW_REPO en este script: $WORKFLOW_REPO"
fi

# Archivos del workflow a instalar (excluir CLAUDE.md, README.md, init.sh)
ALL_FILES=$(echo "$TREE_RESPONSE" \
  | grep -oP '"path":"[^"]*"' \
  | cut -d'"' -f4 \
  | grep -v '"')

WORKFLOW_FILES=$(echo "$ALL_FILES" \
  | grep -E "^(\.claude/|git-hooks/|docs/|sync-workflow\.sh|\.gitignore)" \
  | grep -v "^$" || true)

if [ -z "$WORKFLOW_FILES" ]; then
  err "No se encontraron archivos del workflow en el repositorio.
  Verifica que WORKFLOW_REPO sea correcto: $WORKFLOW_REPO"
fi

TOTAL=$(echo "$WORKFLOW_FILES" | grep -c "." || true)
info "$TOTAL archivos a instalar"

# ─── 5. Descargar e instalar archivos ─────────────────────────────────────────

step "Instalando workflow"

INSTALLED=0
SKIPPED=0
ERRORS=0

while IFS= read -r FILE_PATH; do
  [ -z "$FILE_PATH" ] && continue

  LOCAL_PATH="./$FILE_PATH"
  RAW_URL="$RAW_BASE/$FILE_PATH"

  # Crear directorio si no existe
  $DRY_RUN || mkdir -p "$(dirname "$LOCAL_PATH")"

  if $DRY_RUN; then
    echo "  [dry-run] $FILE_PATH"
    ((INSTALLED++)) || true
    continue
  fi

  HTTP_CODE=$(curl -s -o "${LOCAL_PATH}.tmp" -w "%{http_code}" "${API_HEADERS[@]}" "$RAW_URL" 2>/dev/null)

  if [ "$HTTP_CODE" = "200" ]; then
    mv "${LOCAL_PATH}.tmp" "$LOCAL_PATH"
    # Scripts → ejecutables
    if [[ "$FILE_PATH" == *.sh ]] || [[ "$FILE_PATH" == "git-hooks/"* ]]; then
      chmod +x "$LOCAL_PATH"
    fi
    ((INSTALLED++)) || true
  else
    rm -f "${LOCAL_PATH}.tmp"
    warn "No se pudo descargar: $FILE_PATH (HTTP $HTTP_CODE)"
    ((ERRORS++)) || true
  fi

done <<< "$WORKFLOW_FILES"

ok "$INSTALLED archivos instalados"
[ $ERRORS -gt 0 ] && warn "$ERRORS archivos con error (no críticos — el workflow puede seguir)"

# ─── 6. CLAUDE.md — solo si no existe ────────────────────────────────────────

step "Configurando CLAUDE.md"

if ! $CLAUDE_EXISTS; then
  if $DRY_RUN; then
    info "[dry-run] CLAUDE.md se descargaría desde el repo"
  else
    HTTP_CODE=$(curl -s -o "./CLAUDE.md.tmp" -w "%{http_code}" "${API_HEADERS[@]}" "$RAW_BASE/CLAUDE.md" 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
      mv "./CLAUDE.md.tmp" "./CLAUDE.md"
      ok "CLAUDE.md creado — personalizarlo es el primer paso"
    else
      rm -f "./CLAUDE.md.tmp"
      warn "No se pudo descargar CLAUDE.md (HTTP $HTTP_CODE)"
      warn "Créalo manualmente o cópialo del repo: $WORKFLOW_REPO"
    fi
  fi
else
  info "CLAUDE.md existente preservado sin cambios ✓"
fi

# ─── 7. .gitignore — agregar entradas del workflow ───────────────────────────

step "Actualizando .gitignore"

GITIGNORE_ENTRIES=(
  ""
  "# workflow-ia-web"
  ".env"
  ".env.local"
  ".env.production"
  ".env.staging"
  "*.pem"
  "*.key"
  "# Node"
  "node_modules/"
  "dist/"
  ".next/"
  ".nuxt/"
  ".astro/"
  "# Build cache"
  "*.tsbuildinfo"
  ".turbo/"
  "# Sesiones de Claude Code"
  "docs/reviews/.session-*.md"
)

$DRY_RUN || touch .gitignore
ADDED_ENTRIES=0
for entry in "${GITIGNORE_ENTRIES[@]}"; do
  if ! grep -qxF "$entry" .gitignore 2>/dev/null; then
    if $DRY_RUN; then
      [[ "$entry" != "" ]] && [[ "$entry" != \#* ]] && echo "  [dry-run] .gitignore ← $entry"
    else
      echo "$entry" >> .gitignore
      [[ "$entry" != "" ]] && [[ "$entry" != \#* ]] && { ok ".gitignore ← $entry"; ((ADDED_ENTRIES++)) || true; }
    fi
  fi
done
[ $ADDED_ENTRIES -eq 0 ] && ! $DRY_RUN && info ".gitignore ya estaba actualizado"

# ─── 8. Commit inicial si el repo no tiene commits ───────────────────────────

step "Verificando estado de Git"

COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "0")

if [ "$COMMIT_COUNT" = "0" ] && ! $DRY_RUN; then
  info "Repositorio sin commits — creando commit inicial del workflow..."
  git add .claude/ .gitignore CLAUDE.md docs/ sync-workflow.sh git-hooks/ 2>/dev/null \
    || git add -A 2>/dev/null \
    || true
  git commit -m "chore: workflow-ia-web inicializado" 2>/dev/null \
    && ok "Commit inicial creado" \
    || warn "No se pudo crear el commit inicial — puede que no haya archivos staged"
elif [ "$COMMIT_COUNT" = "0" ] && $DRY_RUN; then
  info "[dry-run] Se crearía commit inicial automáticamente"
else
  ok "Repositorio con $COMMIT_COUNT commit(s) existentes — no se modifica el historial"
  if ! $DRY_RUN; then
    echo ""
    info "Commit sugerido:"
    echo "     git add .claude/ git-hooks/ docs/ sync-workflow.sh .gitignore"
    [ ! $CLAUDE_EXISTS ] && echo "     git add CLAUDE.md"
    echo "     git commit -m \"chore: workflow-ia-web instalado\""
  fi
fi

# ─── 9. Resumen final ─────────────────────────────────────────────────────────

echo ""
echo "${C_GREEN}${C_BOLD}┌──────────────────────────────────────────────────────┐${C_RESET}"
echo "${C_GREEN}${C_BOLD}│   ✅  workflow-ia-web instalado                      │${C_RESET}"
echo "${C_GREEN}${C_BOLD}└──────────────────────────────────────────────────────┘${C_RESET}"
echo ""
if $DRY_RUN; then
  echo "  ${C_YELLOW}[dry-run] No se escribió ningún archivo.${C_RESET}"
  echo "  Ejecuta sin --dry-run para instalar."
else
  echo "  Archivos instalados : $INSTALLED"
  [ $ERRORS -gt 0 ] && echo "  Con errores         : $ERRORS (no bloqueantes)"
  echo ""
  echo "${C_BOLD}  Próximos pasos:${C_RESET}"
  echo ""
  echo "  1. ${C_BLUE}Personaliza CLAUDE.md${C_RESET}"
  echo "     Cambia el Norte del proyecto, el tipo de proyecto"
  echo "     y el stack cuando lo tengas definido."
  echo ""
  echo "  2. ${C_BLUE}Abre Claude Code${C_RESET}"
  echo "     claude"
  echo ""
  echo "  3. ${C_BLUE}Ejecuta /git-setup${C_RESET}"
  echo "     Crea las branches develop y feature/*, instala los"
  echo "     hooks de Git y crea el tag v0.0.1."
  echo ""
  echo "  4. ${C_BLUE}Ejecuta /brief${C_RESET}"
  echo "     Punto de entrada del proyecto. Define el problema,"
  echo "     el usuario y el objetivo medible."
  echo ""
  echo "  Para actualizar el workflow en el futuro:"
  echo "     bash sync-workflow.sh"
  echo ""
  echo "  Documentación completa:"
  echo "     https://github.com/$WORKFLOW_REPO"
fi
echo ""
