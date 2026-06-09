# workflow-ia-web — instalador

Instala [workflow-ia-web](https://github.com/OWNER/workflow-ia-web) en cualquier proyecto web existente con un solo comando.

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/workflow-ia-web/main/init.sh | bash
```

---

## ¿Qué hace este script?

`init.sh` agrega el workflow a tu proyecto sin pisar nada. Específicamente:

1. **Verifica** que estás en un repositorio Git (o te ofrece inicializarlo)
2. **Detecta** el stack web existente (Next.js, Astro, Nuxt, Tailwind, TypeScript, etc.) y lo informa
3. **Descarga** todos los archivos del workflow desde el repo principal usando la GitHub Tree API
4. **Preserva** `CLAUDE.md` si ya existe — nunca lo sobreescribe
5. **Pregunta** antes de sobreescribir `.claude/commands/` si ya hay comandos instalados
6. **Actualiza** `.gitignore` con las entradas necesarias para el workflow
7. **Crea** el commit inicial si el repositorio no tiene ninguno

Lo que **no** hace:
- No toca código de aplicación existente
- No instala dependencias npm ni ningún otro package manager
- No modifica ni crea branches (eso lo hace `/git-setup` dentro de Claude Code)
- No ejecuta ningún comando de build ni test

---

## Requisitos

- `git` instalado y en el PATH
- `curl` instalado y en el PATH
- Repositorio Git inicializado (o el script lo inicializa con tu permiso)

---

## Formas de instalación

### Opción A — curl directo (recomendado)

Desde la raíz de tu proyecto:

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/workflow-ia-web/main/init.sh | bash
```

### Opción B — Descargar y revisar primero

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/workflow-ia-web/main/init.sh -o init.sh
# Revisa el script antes de ejecutarlo
cat init.sh
bash init.sh
```

### Opción C — Dry run (sin escribir nada)

```bash
bash init.sh --dry-run
```

Muestra qué se instalaría sin modificar ningún archivo.

### Opción D — Con token de GitHub (para repos privados o evitar rate limit)

```bash
GITHUB_TOKEN=tu_token_aqui \
  curl -fsSL https://raw.githubusercontent.com/OWNER/workflow-ia-web/main/init.sh | bash
```

---

## Después de instalar

Una vez que el script termina, el flujo es siempre el mismo:

```
1. Personaliza CLAUDE.md
   → Cambia "Norte del proyecto" con el objetivo real del sitio.
   → Actualiza el tipo de proyecto (landing, ecommerce, webapp, etc.)
   → El stack se formaliza más adelante en /architect.

2. Abre Claude Code
   claude

3. Ejecuta /git-setup
   → Crea las branches develop + feature/*
   → Instala los hooks de Git (pre-commit, pre-push, commit-msg)
   → Crea el tag v0.0.1

4. Ejecuta /brief
   → Punto de entrada real del proyecto.
```

---

## Lo que se instala

```
.claude/
├── commands/          18 slash commands (git-setup, brief, discovery … handoff)
├── hooks/             5 hooks de Claude Code
├── settings.json      Configuración de hooks
└── protected.txt      Lista de archivos protegidos

git-hooks/             Hooks de Git versionados (pre-commit, pre-push, commit-msg)
                       /git-setup los copia a .git/hooks/ y les da chmod +x

docs/
├── adr/               Template ADR
├── reviews/           Templates de hallazgos y decisiones
├── ideas-features/    Template de captura de ideas
├── brief/             Template de brief
├── content/           Templates de arquitectura, mensajes y microcopy
├── design/            Template de tokens y componentes
├── analytics/         Template de plan de medición
├── handoff/           Templates de entrega
├── launch-checklist.md
└── tech-debt.md

CLAUDE.md              Solo si no existe en el proyecto
sync-workflow.sh       Script para actualizaciones futuras
.gitignore             Entradas del workflow agregadas sin pisar las existentes
```

---

## Actualizaciones futuras

Este script instala. Para actualizaciones posteriores, usa el script de sync que viene incluido:

```bash
bash sync-workflow.sh           # actualiza comandos y hooks
bash sync-workflow.sh --dry-run # previsualiza qué cambiaría
```

`sync-workflow.sh` nunca toca `CLAUDE.md` — el norte del proyecto y la configuración específica de cada proyecto se preservan siempre.

---

## Estructura de los dos repositorios

Este instalador es el repositorio complementario del template principal:

| Repositorio | Propósito |
|-------------|-----------|
| `OWNER/workflow-ia-web` | Template principal con todos los archivos del workflow. Se usa como GitHub Template para proyectos nuevos o como fuente del instalador. |
| `OWNER/workflow-ia-web-init` | Solo contiene `init.sh` y este README. URL estable para el curl de instalación. |

### ¿Por qué dos repositorios?

La URL del curl de instalación debe ser estable y corta. Si el script vive en el repo principal, cualquier reorganización de carpetas rompe la URL publicada. El repo de init es mínimo e inmutable: solo el script y su documentación.

---

## Personalizar para tu organización

Si haces un fork del workflow para tu equipo, edita estas dos líneas en `init.sh`:

```bash
WORKFLOW_REPO="OWNER/workflow-ia-web"   # ← tu usuario/org en GitHub
BRANCH="main"                           # ← branch de distribución
```

Y actualiza la URL del curl en este README:

```bash
curl -fsSL https://raw.githubusercontent.com/TU_ORG/workflow-ia-web/main/init.sh | bash
```

---

## Troubleshooting

**Error: "Error de GitHub API: Not Found"**
El repositorio aún no está publicado en GitHub, o `WORKFLOW_REPO` en el script no es correcto. Verifica que el repo exista y sea público (o que `GITHUB_TOKEN` tenga acceso).

**Error: "curl es necesario"**
Instala curl: `sudo apt install curl` (Ubuntu/Debian) o `brew install curl` (macOS).

**El script termina pero no hay archivos**
Revisa la salida del script — habrá advertencias con el HTTP code de cada archivo fallido. Si todos son 404, el repositorio fuente no existe todavía.

**Quiero reinstalar desde cero**
```bash
rm -rf .claude/ git-hooks/ docs/ sync-workflow.sh
bash init.sh
```

---

## Licencia

MIT — úsalo, fórkalo, adáptalo.
