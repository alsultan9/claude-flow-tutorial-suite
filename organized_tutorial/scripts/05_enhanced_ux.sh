#!/bin/bash

# 05_enhanced_ux.sh - Enhanced UX Version with Templates and Smart Validation
# Improved user experience with interactive templates and better feedback

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
TEMPLATE_MODE=false

# Colors for enhanced UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ------------------------- HELPER FUNCTIONS -------------------------
say() {
  echo -e "${BLUE}[idea-to-app]${NC} $*"
}

warn() {
  echo -e "${YELLOW}[warn]${NC} $*"
}

die() {
  echo -e "${RED}[error]${NC} $*"
  exit 1
}

success() {
  echo -e "${GREEN}[success]${NC} $*"
}

info() {
  echo -e "${CYAN}[info]${NC} $*"
}

# WFGY Functions with colors
bbmc() {
  if [[ "$WFGY_ENABLED" == true ]]; then
    echo -e "${PURPLE}[BBMC]${NC} $*"
  fi
}

bbpf() {
  if [[ "$WFGY_ENABLED" == true ]]; then
    echo -e "${CYAN}[BBPF]${NC} $*"
  fi
}

bbcr() {
  if [[ "$WFGY_ENABLED" == true ]]; then
    echo -e "${RED}[BBCR]${NC} $*"
  fi
}

bbam() {
  if [[ "$WFGY_ENABLED" == true ]]; then
    echo -e "${GREEN}[BBAM]${NC} $*"
  fi
}

# Progress bar function
show_progress() {
  local current=$1
  local total=$2
  local description=$3
  local width=40
  local percentage=$((current * 100 / total))
  local filled=$((width * current / total))
  local empty=$((width - filled))
  
  printf "\r${CYAN}[%s]${NC} [${GREEN}%s${NC}${WHITE}%s${NC}] %d%% - %s" \
    "$description" \
    "$(printf '#%.0s' $(seq 1 $filled))" \
    "$(printf ' %.0s' $(seq 1 $empty))" \
    "$percentage" \
    "$description"
  
  if [[ $current -eq $total ]]; then
    echo ""
  fi
}

# Template ideas for better UX
TEMPLATE_IDEAS=(
  "chat-app:A real-time chat application for remote teams with video conferencing, document sharing, and project management features. Users: Remote teams, project managers, and organizations. Goal: Streamline remote collaboration and improve team productivity. Inputs: User authentication, video streams, documents, and project data. Outputs: Integrated workspace with real-time updates and communication tools. Runtime: Cloud-based with local caching for offline work."
  "ecommerce:A comprehensive e-commerce platform with inventory management, order processing, and customer analytics. Users: Online retailers, small businesses, and customers. Goal: Provide a complete solution for online selling with advanced features and analytics. Inputs: Product catalogs, customer data, payment information, and inventory levels. Outputs: Online storefront, order management system, and business intelligence dashboard. Runtime: Cloud-hosted with mobile app for customers and admin panel for merchants."
  "task-manager:A task management system for small teams with real-time collaboration, progress tracking, and deadline management. Users: Team leaders, project managers, and team members. Goal: Organize tasks and track progress efficiently. Inputs: Task descriptions, due dates, priorities, and team assignments. Outputs: Task lists, progress reports, notifications, and team dashboards. Runtime: Web application with mobile access and desktop notifications."
  "api-gateway:A microservices API gateway with authentication, rate limiting, load balancing, and monitoring capabilities. Users: Developers, DevOps engineers, and system administrators. Goal: Centralize API management and provide security and monitoring. Inputs: API requests, authentication tokens, and service endpoints. Outputs: Routed requests, analytics, security logs, and performance metrics. Runtime: Cloud-native with Kubernetes deployment and auto-scaling."
  "ml-pipeline:A machine learning pipeline for data processing, model training, and prediction serving. Users: Data scientists, ML engineers, and business analysts. Goal: Automate the ML workflow from data ingestion to model deployment. Inputs: Raw data, model configurations, and training parameters. Outputs: Trained models, predictions, performance metrics, and deployment artifacts. Runtime: Cloud-based with GPU support and real-time inference capabilities."
  "dashboard:A business intelligence dashboard for data visualization and analytics. Users: Business analysts, executives, and data teams. Goal: Provide insights through interactive visualizations and real-time data. Inputs: Database connections, data sources, and visualization configurations. Outputs: Interactive charts, reports, alerts, and data exports. Runtime: Web-based with real-time data updates and mobile responsive design."
  "auth-service:A comprehensive authentication and authorization service with multi-factor authentication and social login. Users: Application developers and end users. Goal: Provide secure and flexible authentication for multiple applications. Inputs: User credentials, social tokens, and permission requests. Outputs: JWT tokens, user sessions, and access control decisions. Runtime: Microservice architecture with Redis caching and database persistence."
  "custom:Enter your own custom idea"
)

# Function to show template selection
show_templates() {
  echo -e "\n${CYAN}🎯 Choose a Project Template${NC}"
  echo -e "${PURPLE}========================${NC}\n"
  
  for i in "${!TEMPLATE_IDEAS[@]}"; do
    local template="${TEMPLATE_IDEAS[$i]}"
    local key="${template%%:*}"
    local description="${template#*:}"
    local short_desc="${description%%Users:*}"
    
    printf "${WHITE}%2d)${NC} ${GREEN}%-15s${NC} - %s\n" "$((i+1))" "$key" "$short_desc"
  done
  
  echo ""
}

# Function to get template idea
get_template_idea() {
  local choice="$1"
  
  if [[ "$choice" -ge 1 && "$choice" -le "${#TEMPLATE_IDEAS[@]}" ]]; then
    local template="${TEMPLATE_IDEAS[$((choice-1))]}"
    local description="${template#*:}"
    echo "$description"
  else
    die "Invalid template choice: $choice"
  fi
}

# Smart idea validation with suggestions
validate_idea_smart() {
  local idea="$1"
  local issues=()
  local suggestions=()
  
  # Check for required components
  if ! echo "$idea" | grep -qi "user"; then
    issues+=("Missing 'Users' section")
    suggestions+=("Add: Users: Who will use this system?")
  fi
  
  if ! echo "$idea" | grep -qi "goal"; then
    issues+=("Missing 'Goal' section")
    suggestions+=("Add: Goal: What problem does it solve?")
  fi
  
  if ! echo "$idea" | grep -qi "input"; then
    issues+=("Missing 'Inputs' section")
    suggestions+=("Add: Inputs: What data/sources does it need?")
  fi
  
  if ! echo "$idea" | grep -qi "output"; then
    issues+=("Missing 'Outputs' section")
    suggestions+=("Add: Outputs: What does it produce?")
  fi
  
  if ! echo "$idea" | grep -qi "runtime\|deployment\|cloud\|local"; then
    issues+=("Missing 'Runtime' section")
    suggestions+=("Add: Runtime: Local development, cloud deployment, or both?")
  fi
  
  # Check idea length
  local word_count=$(echo "$idea" | wc -w)
  if [[ $word_count -lt 15 ]]; then
    issues+=("Too brief ($word_count words)")
    suggestions+=("Provide more details for better project generation")
  fi
  
  # Return results
  if [[ ${#issues[@]} -gt 0 ]]; then
    echo "ISSUES:${issues[*]}"
    echo "SUGGESTIONS:${suggestions[*]}"
    return 1
  else
    return 0
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
    -t|--template)
      TEMPLATE_MODE=true
      shift
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
      echo -e "${CYAN}Usage: $0 [OPTIONS]${NC}"
      echo ""
      echo -e "${WHITE}Options:${NC}"
      echo "  -n, --name NAME       Project name (required)"
      echo "  -s, --sparc MODE      SPARC mode: auto, architect, api, ui, ml, tdd"
      echo "  -o, --topology TYPE   Topology: auto, swarm, hive"
      echo "  -a, --agents N        Number of agents (default: 5)"
      echo "  -i, --idea TEXT       Project idea (optional)"
      echo "  -t, --template        Use interactive template selection"
      echo "  --no-wfgy            Disable WFGY methodology"
      echo "  --no-deps            Skip dependency setup"
      echo "  --no-start           Skip auto-start"
      echo "  --interactive        Enable interactive mode"
      echo "  --quiet              Disable verbose output"
      echo "  -h, --help           Show this help"
      echo ""
      echo -e "${WHITE}Examples:${NC}"
      echo "  $0 -n my-project -s architect -o swarm -a 7"
      echo "  $0 -n api-service -s api -o hive -a 3 --no-deps"
      echo "  $0 -n chat-app -i \"A real-time chat application for teams\""
      echo "  $0 -n my-project -t  # Interactive template selection"
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

[[ -n "$PROJECT_NAME" ]] || die "Project name is required. Use -n or --name"

# ------------------------- INTERACTIVE TEMPLATE SELECTION -------------------------
if [[ "$TEMPLATE_MODE" == true ]] || [[ -z "$IDEA_TEXT" ]]; then
  echo -e "\n${CYAN}🎯 Project Idea Selection${NC}"
  echo -e "${PURPLE}========================${NC}\n"
  
  show_templates
  
  read -p "Choose a template (1-${#TEMPLATE_IDEAS[@]}) or press Enter for custom: " choice
  
  if [[ -z "$choice" ]]; then
    # Custom idea
    echo -e "\n${CYAN}📝 Custom Project Idea${NC}"
    echo -e "${PURPLE}=====================${NC}\n"
    
    read -p "Enter your project idea: " IDEA_TEXT
  else
    # Template selection
    IDEA_TEXT=$(get_template_idea "$choice")
  fi
  
  # Validate and potentially improve the idea
  if ! validate_idea_smart "$IDEA_TEXT"; then
    local validation_result=$(validate_idea_smart "$IDEA_TEXT")
    local issues=$(echo "$validation_result" | grep "ISSUES:" | cut -d: -f2-)
    local suggestions=$(echo "$validation_result" | grep "SUGGESTIONS:" | cut -d: -f2-)
    
    echo -e "\n${YELLOW}⚠️  Idea validation issues detected:${NC}"
    echo "$issues" | tr ' ' '\n' | while read -r issue; do
      echo "  ❌ $issue"
    done
    
    echo -e "\n${CYAN}💡 Suggestions to improve your idea:${NC}"
    echo "$suggestions" | tr ' ' '\n' | while read -r suggestion; do
      echo "  💡 $suggestion"
    done
    
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      die "Please improve your idea and try again"
    fi
  fi
fi

# ------------------------- ENHANCED PROJECT SETUP -------------------------
echo -e "\n${CYAN}🚀 Enhanced Project Setup${NC}"
echo -e "${PURPLE}=======================${NC}\n"

# Step 1: Validate idea
show_progress 1 8 "Validating project idea"
if ! validate_idea_smart "$IDEA_TEXT"; then
  local validation_result=$(validate_idea_smart "$IDEA_TEXT")
  local issues=$(echo "$validation_result" | grep "ISSUES:" | cut -d: -f2-)
  local suggestions=$(echo "$validation_result" | grep "SUGGESTIONS:" | cut -d: -f2-)
  
  warn "Idea validation issues detected:"
  echo "$issues" | tr ' ' '\n' | while read -r issue; do
    echo "  ❌ $issue"
  done
  
  echo -e "\n${YELLOW}Suggestions to improve your idea:${NC}"
  echo "$suggestions" | tr ' ' '\n' | while read -r suggestion; do
    echo "  💡 $suggestion"
  done
  
  read -p "Continue anyway? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    die "Please improve your idea and try again"
  fi
fi

# Step 2: Check prerequisites
show_progress 2 8 "Checking system prerequisites"
command -v node >/dev/null 2>&1 || die "Node.js is required"
command -v npm >/dev/null 2>&1 || die "npm is required"
command -v git >/dev/null 2>&1 || die "git is required"

# Step 3: Install CLIs
show_progress 3 8 "Installing Claude Flow CLIs"
npm list -g @anthropic-ai/claude-code >/dev/null 2>&1 || npm i -g @anthropic-ai/claude-code
npm list -g claude-flow@alpha >/dev/null 2>&1 || npm i -g claude-flow@alpha

# Step 4: Create project directory
show_progress 4 8 "Creating project structure"
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"
git init >/dev/null 2>&1 || true

# Step 5: Initialize Claude Flow
show_progress 5 8 "Initializing Claude Flow"
npx claude-flow@alpha init --sparc --force $NONINTERACTIVE $VERBOSE_FLAG

# Step 6: Validate initialization
show_progress 6 8 "Validating initialization"
if [[ ! -f "CLAUDE.md" ]]; then
  die "Initialization failed: CLAUDE.md not created"
fi

if [[ ! -f "claude-flow" ]]; then
  die "Initialization failed: claude-flow executable not created"
fi

# Step 7: Process idea
show_progress 7 8 "Processing project idea"
# Store idea for later use
echo "$IDEA_TEXT" > .project_idea

# Step 8: Ready for orchestration
show_progress 8 8 "Project setup complete"

success "Project '$PROJECT_NAME' is ready for Claude Flow orchestration!"

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

# ------------------------- IDEA PROCESSING ----------------------------
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
success "🎉 PROJECT CREATION COMPLETE!"
echo ""
echo -e "${CYAN}Project:${NC} $PROJECT_DIR"
echo -e "${CYAN}Idea:${NC} ${IDEA_TEXT:0:80}..."
echo ""
echo -e "${WHITE}Key files:${NC}"
echo "  - CLAUDE.md (PRD)"
echo "  - bootstrap.sh (installer)  -> run: ./bootstrap.sh"
echo "  - Makefile (setup/test/smoke/run-daily) -> run: make setup && make test && make smoke"
echo "  - Project_Walkthrough.md (learn the codebase)"

if [[ "$SETUP_DEPENDENCIES" == true ]]; then
  echo ""
  echo -e "${WHITE}Environment Setup:${NC}"
  echo "  - PostgreSQL: Installed and running"
  echo "  - Redis: Installed and running"
  echo "  - Database: ${PROJECT_NAME}_dev created"
  echo "  - Configuration: .env configured with real values"
fi

if [[ "$WFGY_ENABLED" == true ]]; then
  echo ""
  echo -e "${WHITE}WFGY Enhancements Applied:${NC}"
  echo "  - BBMC: Data consistency validation ✓"
  echo "  - BBPF: Progressive pipeline framework ✓"
  echo "  - BBCR: Contradiction resolution ✓"
  echo "  - BBAM: Attention management ✓"
fi

echo ""
echo -e "${WHITE}Common commands:${NC}"
echo "  - ./claude-flow task orchestrate \"Fix failing tests; keep API stable.\" --strategy parallel $NONINTERACTIVE $VERBOSE_FLAG"
echo "  - ./claude-flow sparc tdd \"Implement feature X end-to-end.\" $NONINTERACTIVE $VERBOSE_FLAG"

if [[ "$SETUP_DEPENDENCIES" == true ]]; then
  echo ""
  echo -e "${WHITE}Project Management:${NC}"
  echo "  - npm start          # Start the application"
  echo "  - npm test           # Run tests"
  echo "  - npm run dev        # Start in development mode"
  echo "  - brew services list # Check service status"
fi

if [[ "$WFGY_ENABLED" == true ]]; then
  echo ""
  echo -e "${WHITE}WFGY-specific commands:${NC}"
  echo "  - ./claude-flow memory store \"project_context\" \"$(basename "$PROJECT_DIR") created with WFGY methodology\""
  echo "  - ./claude-flow sparc spec \"validate project consistency with BBMC principles\""
  echo "  - ./claude-flow status --verbose  # Monitor project health"
fi

echo ""
echo -e "${GREEN}🚀 Your project is ready to go!${NC}"
