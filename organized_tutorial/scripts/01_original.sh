#!/usr/bin/env bash
# idea_to_app.sh
# Turn a plain-English idea into a working repo using Claude Code + Claude Flow — no hand coding.
# macOS-friendly; Linux works with minor tweaks (ffmpeg install hint differs).
set -euo pipefail

# ------------------------- CONFIG DEFAULTS -------------------------
PROJECT_NAME_DEFAULT="my_project"
ROOT_DEFAULT="$HOME/Documents"
AGENTS_DEFAULT=7                   # swarm agent count for initial build
TOPOLOGY_DEFAULT="auto"            # auto | swarm | hive
TEMPLATE_DEFAULT="auto"            # auto | backend-cli | api | web-development | ml-experiment | agent-service
VERBOSE_FLAG="--verbose"           # add "" to silence Flow logs
NONINTERACTIVE="--non-interactive" # always non-interactive
# ------------------------------------------------------------------

# ------------------------- ARG PARSING -----------------------------
usage() {
  cat <<USAGE
Usage: $(basename "$0") [-n project_name] [-r /path/to/root] [-t template] [-o topology] [-a agents] [-q quiet]
  -n  Project name (default: $PROJECT_NAME_DEFAULT)
  -r  Root directory to create project in (default: $ROOT_DEFAULT)
  -t  Template: auto|backend-cli|api|web-development|ml-experiment|agent-service (default: auto)
  -o  Topology: auto|swarm|hive (default: auto)
  -a  Agents count (default: $AGENTS_DEFAULT)
  -q  Quiet mode (less Flow logs)
Examples:
  $(basename "$0") -n youtube_intel
  $(basename "$0") -n youtube_intel -t backend-cli -o swarm -a 7
USAGE
  exit 1
}

PROJECT_NAME="$PROJECT_NAME_DEFAULT"
ROOT="$ROOT_DEFAULT"
TEMPLATE="$TEMPLATE_DEFAULT"
TOPOLOGY="$TOPOLOGY_DEFAULT"
AGENTS="$AGENTS_DEFAULT"

while getopts ":n:r:t:o:a:q" opt; do
  case $opt in
    n) PROJECT_NAME="$OPTARG" ;;
    r) ROOT="$OPTARG" ;;
    t) TEMPLATE="$OPTARG" ;;
    o) TOPOLOGY="$OPTARG" ;;
    a) AGENTS="$OPTARG" ;;
    q) VERBOSE_FLAG="" ;;
    *) usage ;;
  esac
done

PROJECT_DIR="$ROOT/$PROJECT_NAME"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ------------------------- PRECHECKS -------------------------------
say() { printf "\033[1;34m[idea-to-app]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
die() { printf "\033[1;31m[error]\033[0m %s\n" "$*"; exit 1; }

require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing '$1'. Please install it and re-run."; }

say "Checking prerequisites…"
require_cmd node
require_cmd npm

# Python/ffmpeg are handled later by bootstrap.sh that Flow will generate,
# but we hint now to reduce surprises.
if ! command -v python3 >/dev/null 2>&1; then warn "python3 not found; Flow's bootstrap will fail until you install Python 3.11+."; fi
if ! command -v ffmpeg  >/dev/null 2>&1; then warn "ffmpeg not found; Flow's bootstrap will prompt you to install it (brew install ffmpeg)."; fi

# ------------------------- INSTALL CLIS ----------------------------
say "Installing/ensuring Claude Code + Claude Flow CLIs…"
npm list -g @anthropic-ai/claude-code >/dev/null 2>&1 || npm i -g @anthropic-ai/claude-code
npm list -g claude-flow@alpha >/dev/null 2>&1 || npm i -g claude-flow@alpha

# ------------------------- INIT REPO -------------------------------
say "Initializing git repo and Claude Flow state…"
git init >/dev/null 2>&1 || true
claude-flow init $NONINTERACTIVE $VERBOSE_FLAG

# ------------------------- TEMPLATE RESOLUTION ---------------------
apply_template() {
  local t="$1"
  say "Applying template: $t"
  claude-flow templates apply "$t" --output CLAUDE.md $NONINTERACTIVE $VERBOSE_FLAG && return 0
  return 1
}

if [[ "$TEMPLATE" == "auto" ]]; then
  # We let Flow choose based on the idea (next step), but we need a CLAUDE.md holder now.
  # If templates are required immediately, try preferred order; otherwise next orchestrate writes CLAUDE.md anyway.
  apply_template backend-cli || apply_template api || apply_template web-development || touch CLAUDE.md
else
  apply_template "$TEMPLATE" || warn "Template '$TEMPLATE' failed to apply; continuing with empty CLAUDE.md."
  [[ -f CLAUDE.md ]] || touch CLAUDE.md
fi

# ------------------------- CAPTURE IDEA ----------------------------
say "Enter your idea (end with Ctrl-D). Keep it 3–6 sentences: users, goal, inputs/outputs, runtime (local/cloud)."
IDEA_TEXT="$(cat)"

[[ -n "${IDEA_TEXT// }" ]] || die "No idea text provided."

# ------------------------- AUTO-SELECT TEMPLATE+TOPOLOGY + WRITE PRD -------------------------
say "Letting Flow choose template & topology from your idea, draft PRD, then implement…"

TOPOLOGY_INSTR=""
if [[ "$TOPOLOGY" != "auto" ]]; then
  TOPOLOGY_INSTR="Force topology: $TOPOLOGY with $AGENTS agents."
fi

TEMPLATE_INSTR=""
if [[ "$TEMPLATE" != "auto" ]]; then
  TEMPLATE_INSTR="Force template: $TEMPLATE."
fi

ORCH_PROMPT_PRD=$(
  cat <<'EOP'
You are the Build Orchestrator.

1) From the user's idea below, CHOOSE the best Claude Flow template via this rubric:
- backend-cli for data/ETL CLIs and offline analytics
- api for HTTP services
- web-development for UI-first apps
- ml-experiment for modeling/evals
- agent-service for tool-using agents
Print: "TEMPLATE_CHOSEN: <name>".

2) CHOOSE topology:
- Swarm (mesh, 5–8 agents) for parallel scaffolding/big refactors
- Hive mind (3–4 agents) for tightly sequenced, low-thrash tasks
Pick an agent count. Print: "TOPOLOGY_CHOSEN: <swarm|hive> AGENTS: <n>".

3) DRAFT a complete PRD into CLAUDE.md (overwrite file) with:
Objective, Non-goals, Deliverables (dir tree), Tech stack with PINNED dependencies, Task graph,
Verification gates (bootstrap.sh must pass; make test green; domain-specific gates),
Acceptance criteria, Paths/CLI targets, Topology/agents,
Installer requirement: write 'bootstrap.sh' that creates .venv, installs deps, verifies ffmpeg, ensures whisper model,
Makefile: setup/test/smoke/run-daily/verify-citations.

The PRD must be executable by a multi-agent build with ZERO questions.

4) IMPLEMENT the PRD exactly. Create/patch files, run ./bootstrap.sh, run tests, and self-patch once to pass all gates.

Rules:
- Non-interactive; do not ask the user questions.
- At each phase, print files created/modified and a one-line rationale.
- Fail if any gate fails; attempt one auto-patch cycle; then stop with a clear error summary.
EOP
)

# Compose final prompt including user idea and any forced choices
FINAL_PRD_PROMPT=$(
  printf "%s\n\nUser Idea:\n%s\n\n%s\n%s\n" \
    "$ORCH_PROMPT_PRD" \
    "$IDEA_TEXT" \
    "$TEMPLATE_INSTR" \
    "$TOPOLOGY_INSTR"
)

# Run orchestrate to choose template+topology, write PRD, and build
claude-flow orchestrate "$FINAL_PRD_PROMPT" $NONINTERACTIVE $VERBOSE_FLAG

# ------------------------- ENABLE VERIFICATION MODE ----------------
say "Enabling strict verification mode…"
npx claude-flow@alpha init --verify $NONINTERACTIVE >/dev/null
npx claude-flow@alpha verify init strict $NONINTERACTIVE >/dev/null
npx claude-flow@alpha verify status $NONINTERACTIVE || true

# ------------------------- LEARNING WALKTHROUGH --------------------
say "Generating Project_Walkthrough.md so you can learn the patterns…"
claude-flow orchestrate "Read the repo and generate Project_Walkthrough.md covering: module map, execution flow, design patterns, verification gates, and hardening suggestions." $NONINTERACTIVE $VERBOSE_FLAG

# ------------------------- FINAL OUTPUT ----------------------------
say "DONE."
echo "Project: $PROJECT_DIR"
echo "Key files:"
echo "  - CLAUDE.md (PRD)"
echo "  - bootstrap.sh (installer)  -> run: ./bootstrap.sh"
echo "  - Makefile (setup/test/smoke/run-daily) -> run: make setup && make test && make smoke"
echo "  - Project_Walkthrough.md (learn the codebase)"
echo "Common commands:"
echo "  - claude-flow orchestrate \"Fix failing tests; keep API stable.\" $NONINTERACTIVE $VERBOSE_FLAG"
echo "  - claude-flow sparc run dev \"Implement feature X end-to-end.\" $NONINTERACTIVE $VERBOSE_FLAG"
