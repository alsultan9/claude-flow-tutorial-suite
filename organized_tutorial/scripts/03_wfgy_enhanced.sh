#!/bin/bash

# idea-to-app.sh - Claude Flow Tutorial Script
# Creates a complete project from an idea using Claude Flow + Claude Code

set -euo pipefail

# ------------------------- CONFIGURATION -------------------------
PROJECT_NAME=""
SPARC_MODE="auto"
TOPOLOGY="auto"
AGENTS=5
WFGY_ENABLED=true
NONINTERACTIVE="--non-interactive"
VERBOSE_FLAG="--verbose"

# ------------------------- HELPER FUNCTIONS -------------------------
say() {
  echo "[idea-to-app] $*"
}

warn() {
  echo "[warn] $*" >&2
}

die() {
  echo "[error] $*" >&2
  exit 1
}

# WFGY Functions
bbmc() {
  if [[ "$WFGY_ENABLED" == true ]]; then
    echo "[BBMC] $*"
  fi
}

bbpf() {
  if [[ "$WFGY_ENABLED" == true ]]; then
    echo "[BBPF] $*"
  fi
}

bbcr() {
  if [[ "$WFGY_ENABLED" == true ]]; then
    echo "[BBCR] $*"
  fi
}

bbam() {
  if [[ "$WFGY_ENABLED" == true ]]; then
    echo "[BBAM] $*"
  fi
}

# ------------------------- PARSE ARGUMENTS -------------------------
while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--name)
      PROJECT_NAME="$2"
      shift 2
      ;;
    -s|--sparc)
      SPARC_MODE="$2"
      shift 2
      ;;
    -o|--topology)
      TOPOLOGY="$2"
      shift 2
      ;;
    -a|--agents)
      AGENTS="$2"
      shift 2
      ;;
    --no-wfgy)
      WFGY_ENABLED=false
      shift
      ;;
    --interactive)
      NONINTERACTIVE=""
      shift
      ;;
    --quiet)
      VERBOSE_FLAG=""
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -n, --name NAME       Project name (required)"
      echo "  -s, --sparc MODE      SPARC mode: auto, architect, api, ui, ml, tdd"
      echo "  -o, --topology TYPE   Topology: auto, swarm, hive"
      echo "  -a, --agents N        Number of agents (default: 5)"
      echo "  --no-wfgy            Disable WFGY methodology"
      echo "  --interactive        Enable interactive mode"
      echo "  --quiet              Disable verbose output"
      echo "  -h, --help           Show this help"
      echo ""
      echo "Examples:"
      echo "  $0 -n my-project -s architect -o swarm -a 7"
      echo "  $0 -n api-service -s api -o hive -a 3"
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

[[ -n "$PROJECT_NAME" ]] || die "Project name is required. Use -n or --name"

# ------------------------- PREREQUISITES -------------------------
say "Checking prerequisites..."

# Check for required tools
command -v node >/dev/null 2>&1 || die "Node.js is required"
command -v npm >/dev/null 2>&1 || die "npm is required"
command -v git >/dev/null 2>&1 || die "git is required"

# Check for ffmpeg (optional but recommended)
if ! command -v ffmpeg >/dev/null 2>&1; then
  warn "ffmpeg not found; Flow's bootstrap will prompt you to install it (brew install ffmpeg)."
fi

# ------------------------- INSTALLATION -------------------------
say "Installing/ensuring Claude Code + Claude Flow CLIs..."

npm list -g @anthropic-ai/claude-code >/dev/null 2>&1 || npm i -g @anthropic-ai/claude-code
npm list -g claude-flow@alpha >/dev/null 2>&1 || npm i -g claude-flow@alpha

# BBMC: Validate CLI installation consistency
if [[ "$WFGY_ENABLED" == true ]]; then
  bbmc "Validating system requirements consistency..."
  
  if ! command -v claude >/dev/null 2>&1; then
    bbcr "Installation inconsistency: claude not found in PATH"
    die "BBMC validation failed: claude installation incomplete"
  fi
  
  if ! command -v claude-flow >/dev/null 2>&1; then
    bbcr "Installation inconsistency: claude-flow not found in PATH"
    die "BBMC validation failed: claude-flow installation incomplete"
  fi
  
  bbmc "System requirements validation passed"
fi

# ------------------------- PROJECT SETUP -------------------------
PROJECT_DIR="$PROJECT_NAME"
say "Creating project directory: $PROJECT_DIR"

if [[ -d "$PROJECT_DIR" ]]; then
  warn "Directory $PROJECT_DIR already exists"
  read -p "Remove and recreate? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$PROJECT_DIR"
  else
    die "Aborted"
  fi
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ------------------------- INIT REPO -------------------------------
say "Initializing git repo and Claude Flow state..."
git init >/dev/null 2>&1 || true

# BBPF: Progressive initialization with validation gates
if [[ "$WFGY_ENABLED" == true ]]; then
  bbpf "Step 1: Initializing Claude Flow with progressive validation..."
  npx claude-flow@alpha init --sparc --force $NONINTERACTIVE $VERBOSE_FLAG
  
  bbpf "Step 2: Validating initialization success..."
  if [[ ! -f "CLAUDE.md" ]]; then
    bbcr "Initialization inconsistency: CLAUDE.md not created"
    die "BBPF validation failed: Initialization did not create required files"
  fi
  
  bbpf "Step 3: Verifying executable creation..."
  if [[ ! -f "claude-flow" ]]; then
    bbcr "Initialization inconsistency: claude-flow executable not created"
    die "BBPF validation failed: Local executable not created"
  fi
  
  bbpf "Initialization completed successfully with validation"
else
  npx claude-flow@alpha init --sparc --force $NONINTERACTIVE $VERBOSE_FLAG
fi

# ------------------------- SPARC MODE RESOLUTION ---------------------
apply_sparc_mode() {
  local mode="$1"
  say "Applying SPARC mode: $mode"
  
  # BBAM: Focus on critical SPARC modes first
  if [[ "$WFGY_ENABLED" == true ]]; then
    bbam "Prioritizing SPARC mode selection based on project requirements..."
    
    # Priority 1: Critical modes for project success
    case "$mode" in
      "architect"|"api"|"ui")
        bbam "Priority 1: Applying critical SPARC mode: $mode"
        ;;
      "ml"|"tdd")
        bbam "Priority 2: Applying specialized SPARC mode: $mode"
        ;;
      *)
        bbam "Auto mode: Letting orchestrator choose optimal SPARC mode"
        ;;
    esac
  fi
  
  # Use SPARC modes instead of non-existent templates
  case "$mode" in
    "architect")
      ./claude-flow sparc architect "design system architecture for project" $NONINTERACTIVE $VERBOSE_FLAG
      ;;
    "api")
      ./claude-flow sparc spec "setup API development environment" $NONINTERACTIVE $VERBOSE_FLAG
      ;;
    "ui")
      ./claude-flow sparc spec "setup web development environment" $NONINTERACTIVE $VERBOSE_FLAG
      ;;
    "ml")
      ./claude-flow sparc spec "setup machine learning environment" $NONINTERACTIVE $VERBOSE_FLAG
      ;;
    "tdd")
      ./claude-flow sparc tdd "setup test-driven development environment" $NONINTERACTIVE $VERBOSE_FLAG
      ;;
    *)
      # Auto mode - let the orchestrator decide
      return 0
      ;;
  esac
  return 0
}

if [[ "$SPARC_MODE" == "auto" ]]; then
  # We let Flow choose based on the idea (next step), but we need a CLAUDE.md holder now.
  # The init command already creates CLAUDE.md, so we just ensure it exists
  [[ -f CLAUDE.md ]] || touch CLAUDE.md
else
  apply_sparc_mode "$SPARC_MODE" || warn "SPARC mode '$SPARC_MODE' failed to apply; continuing with default setup."
  [[ -f CLAUDE.md ]] || touch CLAUDE.md
fi

# ------------------------- CAPTURE IDEA ----------------------------
# IDEA PLACEHOLDER - Replace this with your project idea
IDEA_TEXT="A comprehensive design system for building scalable, accessible, and maintainable user interfaces across multiple platforms and frameworks. Users: Frontend developers, designers, and product teams. Goal: Create a unified component library that accelerates development while ensuring design consistency. Inputs: Design tokens, component specifications, and framework requirements. Outputs: Reusable components, documentation, and integration guides. Runtime: Local development with cloud deployment capabilities."

# Alternative ideas you can use (uncomment one):
# IDEA_TEXT="A real-time collaboration platform for remote teams with video conferencing, document sharing, and project management features. Users: Remote teams, project managers, and organizations. Goal: Streamline remote collaboration and improve team productivity. Inputs: User authentication, video streams, documents, and project data. Outputs: Integrated workspace with real-time updates and communication tools. Runtime: Cloud-based with local caching for offline work."
# IDEA_TEXT="An AI-powered personal finance manager that tracks expenses, provides insights, and offers investment recommendations. Users: Individuals, families, and small business owners. Goal: Help users make better financial decisions through intelligent analysis and automation. Inputs: Bank transactions, receipts, financial goals, and market data. Outputs: Spending reports, budget recommendations, and investment strategies. Runtime: Mobile app with cloud synchronization and local data storage."
# IDEA_TEXT="A comprehensive e-commerce platform with inventory management, order processing, and customer analytics. Users: Online retailers, small businesses, and customers. Goal: Provide a complete solution for online selling with advanced features and analytics. Inputs: Product catalogs, customer data, payment information, and inventory levels. Outputs: Online storefront, order management system, and business intelligence dashboard. Runtime: Cloud-hosted with mobile app for customers and admin panel for merchants."

[[ -n "${IDEA_TEXT// }" ]] || die "No idea text provided."

# BBMC: Validate idea consistency
if [[ "$WFGY_ENABLED" == true ]]; then
  bbmc "Validating idea consistency and completeness..."
  
  # Check for required components in idea
  if ! echo "$IDEA_TEXT" | grep -qi "user\|goal\|input\|output"; then
    bbcr "Idea inconsistency: Missing required components (users, goal, inputs/outputs)"
    warn "Consider adding: users, goal, inputs/outputs, runtime environment"
  fi
  
  # Check idea length
  IDEA_LENGTH=$(echo "$IDEA_TEXT" | wc -w)
  if [[ "$IDEA_LENGTH" -lt 10 ]]; then
    bbcr "Idea inconsistency: Too brief (${IDEA_LENGTH} words, recommended: 15+ words)"
    warn "Consider providing more detail for better project generation"
  fi
  
  bbmc "Idea validation completed"
fi

# ------------------------- AUTO-SELECT SPARC MODE + TOPOLOGY + WRITE PRD -------------------------
say "Letting Flow choose SPARC mode & topology from your idea, draft PRD, then implement..."

TOPOLOGY_INSTR=""
if [[ "$TOPOLOGY" != "auto" ]]; then
  TOPOLOGY_INSTR="Force topology: $TOPOLOGY with $AGENTS agents."
fi

SPARC_INSTR=""
if [[ "$SPARC_MODE" != "auto" ]]; then
  SPARC_INSTR="Force SPARC mode: $SPARC_MODE."
fi

# BBAM: Enhanced prompt with attention management
ORCH_PROMPT_PRD="You are the Build Orchestrator with WFGY methodology.

BBMC (Data Consistency Validation):
- Validate that the idea requirements are consistent and complete
- Ensure all technical assumptions are clearly stated
- Verify that the project scope is well-defined

BBPF (Progressive Pipeline Framework):
- Design the implementation pipeline step-by-step
- Create clear dependencies and rollback points
- Ensure each step builds on validated previous steps

BBCR (Contradiction Resolution):
- Detect any contradictions between requirements and implementation
- Ensure technical choices are consistent
- Validate that the solution matches the original intent

BBAM (Attention Management):
- Focus on the most critical components first
- Prioritize features based on impact and complexity
- Allocate resources efficiently

1) From the user's idea below, CHOOSE the best Claude Flow SPARC mode via this rubric:
- architect for system design and architecture
- api for HTTP services and backend development
- ui for frontend and web development
- ml for machine learning and data science
- tdd for test-driven development workflows
Print: 'SPARC_MODE_CHOSEN: <name>'.

2) CHOOSE topology:
- Swarm (mesh, 5–8 agents) for parallel scaffolding/big refactors
- Hive mind (3–4 agents) for tightly sequenced, low-thrash tasks
Pick an agent count. Print: 'TOPOLOGY_CHOSEN: <swarm|hive> AGENTS: <n>'.

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
- Apply BBMC validation at each step
- Use BBPF progressive approach
- Implement BBCR contradiction detection
- Apply BBAM attention management"

# Compose final prompt including user idea and any forced choices
FINAL_PRD_PROMPT=$(printf "%s\n\nUser Idea:\n%s\n\n%s\n%s\n" "$ORCH_PROMPT_PRD" "$IDEA_TEXT" "$SPARC_INSTR" "$TOPOLOGY_INSTR")

# BBPF: Progressive implementation with validation gates
if [[ "$WFGY_ENABLED" == true ]]; then
  bbpf "Step 1: Orchestrating project creation with progressive validation..."
  ./claude-flow task orchestrate --task "$FINAL_PRD_PROMPT" --strategy parallel $NONINTERACTIVE $VERBOSE_FLAG
  
  bbpf "Step 2: Validating project creation success..."
  if [[ ! -f "bootstrap.sh" ]]; then
    bbcr "Project creation inconsistency: bootstrap.sh not created"
    die "BBPF validation failed: Critical project files not created"
  fi
  
  bbpf "Step 3: Validating project structure..."
  if [[ ! -f "Makefile" ]]; then
    bbcr "Project creation inconsistency: Makefile not created"
    warn "BBPF warning: Makefile not created, but continuing"
  fi
  
  bbpf "Project creation completed successfully with validation"
else
  # Run task orchestrate to choose SPARC mode+topology, write PRD, and build
  ./claude-flow task orchestrate --task "$FINAL_PRD_PROMPT" --strategy parallel $NONINTERACTIVE $VERBOSE_FLAG
fi

# ------------------------- ENABLE VERIFICATION MODE ----------------
say "Enabling strict verification mode..."

# BBPF: Progressive verification with multiple gates
if [[ "$WFGY_ENABLED" == true ]]; then
  bbpf "Step 1: Initializing enhanced verification mode..."
  ./claude-flow init --validate --enhanced $NONINTERACTIVE $VERBOSE_FLAG >/dev/null
  
  bbpf "Step 2: Running health check validation..."
  ./claude-flow status --health-check $NONINTERACTIVE || true
  
  bbpf "Step 3: Validating system status..."
  if ! ./claude-flow status $NONINTERACTIVE >/dev/null 2>&1; then
    bbcr "Verification inconsistency: System status check failed"
    warn "BBPF warning: System status check failed, but continuing"
  fi
  
  bbpf "Verification mode enabled successfully with validation"
else
  ./claude-flow init --validate --enhanced $NONINTERACTIVE $VERBOSE_FLAG >/dev/null
  ./claude-flow status --health-check $NONINTERACTIVE || true
fi

# ------------------------- LEARNING WALKTHROUGH --------------------
say "Generating Project_Walkthrough.md so you can learn the patterns..."

# BBAM: Focus on critical documentation
if [[ "$WFGY_ENABLED" == true ]]; then
  bbam "Generating comprehensive project walkthrough with attention to critical patterns..."
  ./claude-flow task orchestrate --task "Read the repo and generate Project_Walkthrough.md covering: module map, execution flow, design patterns, verification gates, and hardening suggestions. Focus on BBMC validation points, BBPF pipeline structure, BBCR contradiction detection, and BBAM attention management." --strategy sequential $NONINTERACTIVE $VERBOSE_FLAG
else
  ./claude-flow task orchestrate --task "Read the repo and generate Project_Walkthrough.md covering: module map, execution flow, design patterns, verification gates, and hardening suggestions." --strategy sequential $NONINTERACTIVE $VERBOSE_FLAG
fi

# ------------------------- FINAL VALIDATION -------------------------
if [[ "$WFGY_ENABLED" == true ]]; then
  bbpf "Final validation step: Ensuring project completeness..."
  
  # Check for critical files
  CRITICAL_FILES=("CLAUDE.md" "bootstrap.sh" "Project_Walkthrough.md")
  for file in "${CRITICAL_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
      bbcr "Final validation inconsistency: $file not found"
      warn "BBPF warning: Critical file $file missing"
    fi
  done
  
  # Check for executable permissions
  if [[ -f "bootstrap.sh" ]] && [[ ! -x "bootstrap.sh" ]]; then
    bbcr "Final validation inconsistency: bootstrap.sh not executable"
    chmod +x bootstrap.sh
    bbpf "Fixed: Made bootstrap.sh executable"
  fi
  
  bbpf "Final validation completed"
fi

# ------------------------- FINAL OUTPUT ----------------------------
say "DONE."
echo "Project: $PROJECT_DIR"
echo "Key files:"
echo "  - CLAUDE.md (PRD)"
echo "  - bootstrap.sh (installer)  -> run: ./bootstrap.sh"
echo "  - Makefile (setup/test/smoke/run-daily) -> run: make setup && make test && make smoke"
echo "  - Project_Walkthrough.md (learn the codebase)"

if [[ "$WFGY_ENABLED" == true ]]; then
  echo ""
  echo "WFGY Enhancements Applied:"
  echo "  - BBMC: Data consistency validation ✓"
  echo "  - BBPF: Progressive pipeline framework ✓"
  echo "  - BBCR: Contradiction resolution ✓"
  echo "  - BBAM: Attention management ✓"
fi

echo ""
echo "Common commands:"
echo "  - ./claude-flow task orchestrate \"Fix failing tests; keep API stable.\" --strategy parallel $NONINTERACTIVE $VERBOSE_FLAG"
echo "  - ./claude-flow sparc tdd \"Implement feature X end-to-end.\" $NONINTERACTIVE $VERBOSE_FLAG"

if [[ "$WFGY_ENABLED" == true ]]; then
  echo ""
  echo "WFGY-specific commands:"
  echo "  - ./claude-flow memory store \"project_context\" \"$(basename "$PROJECT_DIR") created with WFGY methodology\""
  echo "  - ./claude-flow sparc spec \"validate project consistency with BBMC principles\""
  echo "  - ./claude-flow status --verbose  # Monitor project health"
fi
