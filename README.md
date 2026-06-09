# workflow-ia-web — instalador

Agrega [workflow-ia-web](https://github.com/OWNER/workflow-ia-web) a cualquier proyecto web con un solo comando — nuevo o existente.

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/workflow-ia-web/main/init.sh | bash
```

---

## Elige tu punto de entrada

Hay tres formas de empezar según tu situación:

### 🟢 Proyecto nuevo desde cero

Usa el repo principal directamente como GitHub Template — es la forma más limpia:

1. Haz clic en **Use this template** en [workflow-ia-web](https://github.com/OWNER/workflow-ia-web)
2. Crea el repositorio del proyecto
3. Clónalo y abre Claude Code
4. Ejecuta `/git-setup` → `/brief`

No necesitas `init.sh` para este caso.

---

### 🟡 Proyecto nuevo, sin usar el Template button

Directorio vacío, quieres el workflow pero no usaste el Template button de GitHub:

```bash
mkdir mi-proyecto && cd mi-proyecto
git init
curl -fsSL https://raw.githubusercontent.com/OWNER/workflow-ia-web/main/init.sh | bash
```

El script detecta que no hay commits y crea el commit inicial automáticamente.

---

### 🔵 Proyecto existente

Ya tienes código. Quieres agregar el workflow sin tocar nada:

```bash
cd mi-proyecto-existente
curl -fsSL https://raw.githubusercontent.com/OWNER/workflow-ia-web/main/init.sh | bash
```

El script preserva todo lo que ya existe: `CLAUDE.md`, comandos previos en `.claude/commands/`, `.gitignore`, código de aplicación. No crea commits automáticos — te sugiere el comando para que tú lo ejecutes.

---

En los tres casos, una vez que termina el script el flujo es el mismo:

```
1. Personaliza CLAUDE.md          → ajusta el Norte del proyecto
2. claude                         → abre Claude Code
3. /git-setup                     → branches + hooks de Git + tag v0.0.1
4. /brief                         → punto de entrada real del proyecto
```

---

## ¿Qué hace el script exactamente?

1. **Verifica** que estás en un repositorio Git — o te ofrece inicializarlo si no existe
2. **Detecta** el stack web presente: Next.js, Astro, Nuxt, SvelteKit, Tailwind, TypeScript, Vercel, Netlify, etc.
3. **Descarga** todos los archivos del workflow desde el repo principal usando la GitHub Tree API
4. **Preserva** `CLAUDE.md` si ya existe — nunca lo sobreescribe
5. **Pregunta** antes de sobreescribir `.claude/commands/` si ya hay comandos instalados
6. **Actualiza** `.gitignore` con las entradas necesarias (`.env`, `node_modules/`, `.next/`, etc.)
7. **Crea** el commit inicial solo si el repo no tiene ningún commit todavía

Lo que **no** hace:
- No toca código de aplicación existente
- No instala dependencias npm ni ningún otro package manager
- No modifica ni crea branches (eso lo hace `/git-setup` dentro de Claude Code)
- No ejecuta ningún comando de build ni test

---

## Requisitos

- `git` instalado y en el PATH
- `curl` instalado y en el PATH

---

## Opciones del script

### Dry run — ver qué se instalaría sin escribir nada

```bash
bash init.sh --dry-run
```

### Descargar y revisar antes de ejecutar

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/workflow-ia-web/main/init.sh -o init.sh
cat init.sh   # revísalo
bash init.sh
```

### Con token de GitHub (repos privados o evitar rate limit)

```bash
GITHUB_TOKEN=tu_token_aqui \
  curl -fsSL https://raw.githubusercontent.com/OWNER/workflow-ia-web/main/init.sh | bash
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

Este script instala. Para actualizaciones posteriores, usa `sync-workflow.sh`:

```bash
bash sync-workflow.sh           # actualiza comandos y hooks
bash sync-workflow.sh --dry-run # previsualiza qué cambiaría
```

`sync-workflow.sh` nunca toca `CLAUDE.md` — el norte del proyecto y la configuración específica de cada proyecto se preservan siempre.

---

## Estructura de los dos repositorios

| Repositorio | Propósito |
|-------------|-----------|
| `OWNER/workflow-ia-web` | Template principal. Contiene todos los archivos del workflow. Se usa como GitHub Template o como fuente del instalador. |
| `OWNER/workflow-ia-web-init` | Solo contiene `init.sh` y este README. URL estable para el curl de instalación. |

**¿Por qué dos repositorios?** La URL del curl debe ser estable. Si el script viviera en el repo principal, cualquier reorganización de carpetas rompería la URL publicada. Este repo es mínimo e inmutable: solo el script y su documentación.

---

## Personalizar para tu organización

Si haces un fork del workflow para tu equipo, edita estas dos líneas en `init.sh`:

```bash
WORKFLOW_REPO="OWNER/workflow-ia-web"   # ← tu usuario/org en GitHub
BRANCH="main"                           # ← branch de distribución
```

Y actualiza la URL del curl en este README.

---

## Troubleshooting

**"Error de GitHub API: Not Found"**
El repositorio aún no está publicado, o `WORKFLOW_REPO` en el script es incorrecto. Verifica que el repo exista y sea público (o que `GITHUB_TOKEN` tenga acceso si es privado).

**"curl es necesario"**
`sudo apt install curl` (Ubuntu/Debian) · `brew install curl` (macOS)

**El script termina sin archivos instalados**
Habrá advertencias con el HTTP code de cada descarga fallida. Si todos son 404, el repo fuente no existe todavía.

**Reinstalar desde cero**
```bash
rm -rf .claude/ git-hooks/ docs/ sync-workflow.sh
bash init.sh
```

---

## Licencia

MIT — úsalo, fórkalo, adáptalo.
