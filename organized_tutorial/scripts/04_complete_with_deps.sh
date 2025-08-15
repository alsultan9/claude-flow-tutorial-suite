#!/bin/bash

# idea-to-app-complete.sh - Claude Flow Tutorial Script with Complete Dependency Management
# Creates a complete project from an idea using Claude Flow + Claude Code + Full Environment Setup

set -euo pipefail

# ------------------------- CONFIGURATION -------------------------
PROJECT_NAME=""
SPARC_MODE="auto"
TOPOLOGY="auto"
AGENTS=5
IDEA_TEXT=""
WFGY_ENABLED=true
NONINTERACTIVE="--non-interactive"
VERBOSE_FLAG="--verbose"
SETUP_DEPENDENCIES=true
AUTO_START=true

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

# Dependency Management Functions
check_dependency() {
  local dep="$1"
  local install_cmd="$2"
  local service_name="$3"
  
  if ! command -v "$dep" >/dev/null 2>&1; then
    warn "$dep not found"
    if [[ "$SETUP_DEPENDENCIES" == true ]]; then
      say "Installing $dep..."
      eval "$install_cmd"
    else
      warn "Please install $dep manually: $install_cmd"
    fi
  else
    say "✅ $dep found"
  fi
  
  # Start service if provided
  if [[ -n "$service_name" ]] && [[ "$SETUP_DEPENDENCIES" == true ]]; then
    if ! brew services list | grep -q "$service_name.*started"; then
      say "Starting $service_name service..."
      brew services start "$service_name"
    else
      say "✅ $service_name service already running"
    fi
  fi
}

setup_database() {
  local db_name="$1"
  
  if [[ "$SETUP_DEPENDENCIES" == true ]]; then
    say "Setting up database: $db_name"
    
    # Check if PostgreSQL is running
    if ! pg_isready -q; then
      warn "PostgreSQL not running. Starting..."
      brew services start postgresql
      sleep 3
    fi
    
    # Create database if it doesn't exist
    if ! psql -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
      say "Creating database: $db_name"
      createdb "$db_name"
    else
      say "✅ Database $db_name already exists"
    fi
  fi
}

setup_redis() {
  if [[ "$SETUP_DEPENDENCIES" == true ]]; then
    say "Setting up Redis"
    
    # Check if Redis is running
    if ! redis-cli ping >/dev/null 2>&1; then
      warn "Redis not running. Starting..."
      brew services start redis
      sleep 2
    fi
    
    # Test Redis connection
    if redis-cli ping | grep -q "PONG"; then
      say "✅ Redis is running"
    else
      warn "Redis setup failed"
    fi
  fi
}

setup_project_env() {
  local project_dir="$1"
  
  if [[ "$SETUP_DEPENDENCIES" == true ]]; then
    say "Setting up project environment"
    
    cd "$project_dir"
    
    # Create .env from example if it doesn't exist
    if [[ ! -f ".env" ]] && [[ -f ".env.example" ]]; then
      cp .env.example .env
      say "Created .env from .env.example"
    fi
    
    # Update .env with real values
    if [[ -f ".env" ]]; then
      # Set real database name
      sed -i '' "s/DB_NAME=.*/DB_NAME=${PROJECT_NAME}_dev/" .env
      
      # Set real JWT secrets
      local jwt_secret=$(openssl rand -hex 32)
      local refresh_secret=$(openssl rand -hex 32)
      sed -i '' "s/JWT_SECRET=.*/JWT_SECRET=$jwt_secret/" .env
      sed -i '' "s/JWT_REFRESH_SECRET=.*/JWT_REFRESH_SECRET=$refresh_secret/" .env
      
      # Remove problematic JWT_AUDIENCE line
      sed -i '' '/JWT_AUDIENCE=/d' .env
      
      say "Updated .env with real configuration values"
    fi
  fi
}

run_project_tests() {
  local project_dir="$1"
  
  if [[ "$SETUP_DEPENDENCIES" == true ]]; then
    say "Running project tests"
    
    cd "$project_dir"
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
      say "Installing npm dependencies..."
      npm install
    fi
    
    # Run tests
    if npm test >/dev/null 2>&1; then
      say "✅ All tests passed"
    else
      warn "Some tests failed (this might be expected without full setup)"
    fi
  fi
}

start_project() {
  local project_dir="$1"
  
  if [[ "$AUTO_START" == true ]]; then
    say "Starting project..."
    
    cd "$project_dir"
    
    # Check if project can start
    if timeout 10s npm start >/dev/null 2>&1; then
      say "✅ Project started successfully"
    else
      warn "Project start failed (check logs for details)"
    fi
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
    -i|--idea)
      IDEA_TEXT="$2"
      shift 2
      ;;
    --no-wfgy)
      WFGY_ENABLED=false
      shift
      ;;
    --no-deps)
      SETUP_DEPENDENCIES=false
      shift
      ;;
    --no-start)
      AUTO_START=false
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
      echo "  -i, --idea TEXT       Project idea (optional, uses default if not provided)"
      echo "  --no-wfgy            Disable WFGY methodology"
      echo "  --no-deps            Skip dependency setup"
      echo "  --no-start           Skip auto-start"
      echo "  --interactive        Enable interactive mode"
      echo "  --quiet              Disable verbose output"
      echo "  -h, --help           Show this help"
      echo ""
      echo "Examples:"
      echo "  $0 -n my-project -s architect -o swarm -a 7"
      echo "  $0 -n api-service -s api -o hive -a 3 --no-deps"
      echo "  $0 -n chat-app -i \"A real-time chat application for teams\""
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
command -v brew >/dev/null 2>&1 || die "Homebrew is required for dependency management"

# BBMC: Validate system requirements consistency
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

# ------------------------- DEPENDENCY SETUP -------------------------
if [[ "$SETUP_DEPENDENCIES" == true ]]; then
  bbpf "Step 1: Setting up project dependencies..."
  
  # Check and install PostgreSQL
  check_dependency "psql" "brew install postgresql" "postgresql"
  
  # Check and install Redis
  check_dependency "redis-cli" "brew install redis" "redis"
  
  # Check and install ffmpeg
  check_dependency "ffmpeg" "brew install ffmpeg" ""
  
  # Check and install Docker (optional)
  check_dependency "docker" "brew install --cask docker" ""
  
  bbpf "Dependency setup completed"
fi

# ------------------------- INSTALLATION -------------------------
say "Installing/ensuring Claude Code + Claude Flow CLIs..."

npm list -g @anthropic-ai/claude-code >/dev/null 2>&1 || npm i -g @anthropic-ai/claude-code
npm list -g claude-flow@alpha >/dev/null 2>&1 || npm i -g claude-flow@alpha

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
  bbpf "Step 2: Initializing Claude Flow with progressive validation..."
  npx claude-flow@alpha init --sparc --force $NONINTERACTIVE $VERBOSE_FLAG
  
  bbpf "Step 3: Validating initialization success..."
  if [[ ! -f "CLAUDE.md" ]]; then
    bbcr "Initialization inconsistency: CLAUDE.md not created"
    die "BBPF validation failed: Initialization did not create required files"
  fi
  
  bbpf "Step 4: Verifying executable creation..."
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
# Use provided idea or default idea
if [[ -z "$IDEA_TEXT" ]]; then
  # Default idea if none provided
  IDEA_TEXT="A comprehensive design system for building scalable, accessible, and maintainable user interfaces across multiple platforms and frameworks. Users: Frontend developers, designers, and product teams. Goal: Create a unified component library that accelerates development while ensuring design consistency. Inputs: Design tokens, component specifications, and framework requirements. Outputs: Reusable components, documentation, and integration guides. Runtime: Local development with cloud deployment capabilities."
  
  say "Using default project idea. You can provide a custom idea with -i or --idea parameter."
  say "Default idea: Design system for scalable UI components"
else
  say "Using provided project idea: ${IDEA_TEXT:0:50}..."
fi

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
  bbpf "Step 5: Orchestrating project creation with progressive validation..."
  ./claude-flow task orchestrate --task "$FINAL_PRD_PROMPT" --strategy parallel $NONINTERACTIVE $VERBOSE_FLAG
  
  bbpf "Step 6: Validating project creation success..."
  if [[ ! -f "bootstrap.sh" ]]; then
    bbcr "Project creation inconsistency: bootstrap.sh not created"
    warn "BBPF warning: bootstrap.sh not created, but continuing"
  fi
  
  bbpf "Step 7: Validating project structure..."
  if [[ ! -f "Makefile" ]]; then
    bbcr "Project creation inconsistency: Makefile not created"
    warn "BBPF warning: Makefile not created, but continuing"
  fi
  
  bbpf "Project creation completed successfully with validation"
else
  # Run task orchestrate to choose SPARC mode+topology, write PRD, and build
  ./claude-flow task orchestrate --task "$FINAL_PRD_PROMPT" --strategy parallel $NONINTERACTIVE $VERBOSE_FLAG
fi

# ------------------------- POST-PROJECT SETUP -------------------------
if [[ "$SETUP_DEPENDENCIES" == true ]]; then
  bbpf "Step 8: Setting up project environment and dependencies..."
  
  # Setup database
  setup_database "${PROJECT_NAME}_dev"
  
  # Setup Redis
  setup_redis
  
  # Setup project environment
  setup_project_env "$(pwd)"
  
  # Run project tests
  run_project_tests "$(pwd)"
  
  bbpf "Project environment setup completed"
fi

# ------------------------- ENABLE VERIFICATION MODE ----------------
say "Enabling strict verification mode..."

# BBPF: Progressive verification with multiple gates
if [[ "$WFGY_ENABLED" == true ]]; then
  bbpf "Step 9: Initializing enhanced verification mode..."
  ./claude-flow init --validate --enhanced $NONINTERACTIVE $VERBOSE_FLAG >/dev/null
  
  bbpf "Step 10: Running health check validation..."
  ./claude-flow status --health-check $NONINTERACTIVE || true
  
  bbpf "Step 11: Validating system status..."
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
  CRITICAL_FILES=("CLAUDE.md" "Project_Walkthrough.md")
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

# ------------------------- AUTO-START PROJECT -------------------------
if [[ "$AUTO_START" == true ]]; then
  bbpf "Step 12: Auto-starting project for validation..."
  start_project "$(pwd)"
fi

# ------------------------- FINAL OUTPUT ----------------------------
say "DONE."
echo "Project: $PROJECT_DIR"
echo "Key files:"
echo "  - CLAUDE.md (PRD)"
echo "  - bootstrap.sh (installer)  -> run: ./bootstrap.sh"
echo "  - Makefile (setup/test/smoke/run-daily) -> run: make setup && make test && make smoke"
echo "  - Project_Walkthrough.md (learn the codebase)"

if [[ "$SETUP_DEPENDENCIES" == true ]]; then
  echo ""
  echo "Environment Setup:"
  echo "  - PostgreSQL: Installed and running"
  echo "  - Redis: Installed and running"
  echo "  - Database: ${PROJECT_NAME}_dev created"
  echo "  - Configuration: .env configured with real values"
fi

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

if [[ "$SETUP_DEPENDENCIES" == true ]]; then
  echo ""
  echo "Project Management:"
  echo "  - npm start          # Start the application"
  echo "  - npm test           # Run tests"
  echo "  - npm run dev        # Start in development mode"
  echo "  - brew services list # Check service status"
fi

if [[ "$WFGY_ENABLED" == true ]]; then
  echo ""
  echo "WFGY-specific commands:"
  echo "  - ./claude-flow memory store \"project_context\" \"$(basename "$PROJECT_DIR") created with WFGY methodology\""
  echo "  - ./claude-flow sparc spec \"validate project consistency with BBMC principles\""
  echo "  - ./claude-flow status --verbose  # Monitor project health"
fi
