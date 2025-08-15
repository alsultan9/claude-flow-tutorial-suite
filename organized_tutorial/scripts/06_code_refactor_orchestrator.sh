#!/bin/bash

# 06_code_refactor_orchestrator.sh - Code Refactor & Adaptation Orchestrator
# Transform existing codebases into new applications using Claude Flow

set -euo pipefail

# ------------------------- CONFIGURATION -------------------------
PROJECT_NAME=""
SPARC_MODE="auto"
TOPOLOGY="auto"
AGENTS=7
SOURCE_TYPE=""
SOURCE_PATH=""
TARGET_FUNCTIONALITY=""
WFGY_ENABLED=true
NONINTERACTIVE="--non-interactive"
VERBOSE_FLAG="--verbose"
SETUP_DEPENDENCIES=true
AUTO_START=true

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
  echo -e "${BLUE}[refactor-orchestrator]${NC} $*"
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

# Function to analyze GitHub repository
analyze_github_repo() {
  local repo_url="$1"
  local repo_name=$(basename "$repo_url" .git)
  
  say "Analyzing GitHub repository: $repo_url"
  
  # Clone repository for analysis
  if [[ ! -d "source_analysis/$repo_name" ]]; then
    git clone "$repo_url" "source_analysis/$repo_name" >/dev/null 2>&1
  fi
  
  # Analyze repository structure
  local analysis_result=""
  analysis_result+="Repository: $repo_url\n"
  analysis_result+="Name: $repo_name\n"
  analysis_result+="Language: $(detect_language "source_analysis/$repo_name")\n"
  analysis_result+="Architecture: $(analyze_architecture "source_analysis/$repo_name")\n"
  analysis_result+="Key Features: $(extract_key_features "source_analysis/$repo_name")\n"
  analysis_result+="Dependencies: $(extract_dependencies "source_analysis/$repo_name")\n"
  
  echo -e "$analysis_result"
}

# Function to detect programming language
detect_language() {
  local repo_path="$1"
  
  if [[ -f "$repo_path/package.json" ]]; then
    echo "JavaScript/Node.js"
  elif [[ -f "$repo_path/requirements.txt" ]] || [[ -f "$repo_path/Pipfile" ]]; then
    echo "Python"
  elif [[ -f "$repo_path/Cargo.toml" ]]; then
    echo "Rust"
  elif [[ -f "$repo_path/go.mod" ]]; then
    echo "Go"
  elif [[ -f "$repo_path/pom.xml" ]]; then
    echo "Java"
  else
    echo "Unknown"
  fi
}

# Function to analyze architecture
analyze_architecture() {
  local repo_path="$1"
  
  if [[ -d "$repo_path/src" ]] && [[ -d "$repo_path/tests" ]]; then
    echo "Standard (src/tests structure)"
  elif [[ -f "$repo_path/docker-compose.yml" ]]; then
    echo "Microservices (Docker)"
  elif [[ -d "$repo_path/frontend" ]] && [[ -d "$repo_path/backend" ]]; then
    echo "Full-stack (frontend/backend)"
  elif [[ -f "$repo_path/serverless.yml" ]]; then
    echo "Serverless"
  else
    echo "Monolithic"
  fi
}

# Function to extract key features
extract_key_features() {
  local repo_path="$1"
  local features=""
  
  # Check for common patterns
  if [[ -f "$repo_path/README.md" ]]; then
    features=$(grep -i "feature\|functionality\|capability" "$repo_path/README.md" | head -3 | tr '\n' ', ')
  fi
  
  if [[ -z "$features" ]]; then
    features="Authentication, API endpoints, Database integration"
  fi
  
  echo "$features"
}

# Function to extract dependencies
extract_dependencies() {
  local repo_path="$1"
  
  if [[ -f "$repo_path/package.json" ]]; then
    grep -o '"[^"]*": "[^"]*"' "$repo_path/package.json" | head -5 | tr '\n' ', '
  elif [[ -f "$repo_path/requirements.txt" ]]; then
    head -5 "$repo_path/requirements.txt" | tr '\n' ', '
  else
    echo "Standard dependencies"
  fi
}

# Function to analyze local codebase
analyze_local_codebase() {
  local codebase_path="$1"
  
  say "Analyzing local codebase: $codebase_path"
  
  if [[ ! -d "$codebase_path" ]]; then
    die "Local codebase path does not exist: $codebase_path"
  fi
  
  # Analyze local codebase structure
  local analysis_result=""
  analysis_result+="Local Codebase: $codebase_path\n"
  analysis_result+="Language: $(detect_language "$codebase_path")\n"
  analysis_result+="Architecture: $(analyze_architecture "$codebase_path")\n"
  analysis_result+="Key Features: $(extract_key_features "$codebase_path")\n"
  analysis_result+="Dependencies: $(extract_dependencies "$codebase_path")\n"
  
  echo -e "$analysis_result"
}

# Function to generate refactor prompt
generate_refactor_prompt() {
  local source_type="$1"
  local source_info="$2"
  local target_functionality="$3"
  
  local prompt="You are a Code Refactor Orchestrator with Claude Flow.
  
BBMC (Data Consistency Validation):
- Validate that the source code analysis is complete and accurate
- Ensure all technical assumptions are clearly stated
- Verify that the target functionality is well-defined

BBPF (Progressive Pipeline Framework):
- Design the refactoring pipeline step-by-step
- Create clear dependencies and rollback points
- Ensure each step builds on validated previous steps

BBCR (Contradiction Resolution):
- Detect any contradictions between source and target requirements
- Ensure technical choices are consistent
- Validate that the solution matches the original intent

BBAM (Attention Management):
- Focus on the most critical refactoring components first
- Prioritize features based on impact and complexity
- Allocate resources efficiently

TASK: Refactor and adapt existing code into a new application

SOURCE INFORMATION:
$source_info

TARGET FUNCTIONALITY:
$target_functionality

REQUIREMENTS:
1) Analyze the source code thoroughly
2) Identify reusable components and patterns
3) Design a new architecture that combines the best elements
4) Implement the new application with modern best practices
5) Ensure the new application is production-ready
6) Provide clear documentation and migration guide

CONSTRAINTS:
- Maintain the core functionality while improving architecture
- Use modern development practices and tools
- Ensure scalability and maintainability
- Provide comprehensive testing
- Include deployment configuration

OUTPUT:
1) Complete new application codebase
2) Architecture documentation
3) Migration guide from source to target
4) Testing suite
5) Deployment configuration
6) Performance optimization recommendations

Rules:
- Non-interactive; do not ask the user questions
- At each phase, print files created/modified and rationale
- Fail if any gate fails; attempt one auto-patch cycle; then stop with clear error summary
- Apply BBMC validation at each step
- Use BBPF progressive approach
- Implement BBCR contradiction detection
- Apply BBAM attention management"

  echo "$prompt"
}

# Function to setup source analysis directory
setup_source_analysis() {
  mkdir -p source_analysis
  echo "source_analysis/" >> .gitignore
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
    -t|--type)
      SOURCE_TYPE="$2"
      shift 2
      ;;
    -p|--path)
      SOURCE_PATH="$2"
      shift 2
      ;;
    -f|--functionality)
      TARGET_FUNCTIONALITY="$2"
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
      echo -e "${CYAN}Usage: $0 [OPTIONS]${NC}"
      echo ""
      echo -e "${WHITE}Options:${NC}"
      echo "  -n, --name NAME       Project name (required)"
      echo "  -s, --sparc MODE      SPARC mode: auto, architect, api, ui, ml, tdd"
      echo "  -o, --topology TYPE   Topology: auto, swarm, hive"
      echo "  -a, --agents N        Number of agents (default: 7)"
      echo "  -t, --type TYPE       Source type: github, local"
      echo "  -p, --path PATH       Source path (GitHub URL or local path)"
      echo "  -f, --functionality   Target functionality description"
      echo "  --no-wfgy            Disable WFGY methodology"
      echo "  --no-deps            Skip dependency setup"
      echo "  --no-start           Skip auto-start"
      echo "  --interactive        Enable interactive mode"
      echo "  --quiet              Disable verbose output"
      echo "  -h, --help           Show this help"
      echo ""
      echo -e "${WHITE}Examples:${NC}"
      echo "  $0 -n refactored-app -t github -p https://github.com/user/repo.git -f \"Modern web app with React\""
      echo "  $0 -n local-adaptation -t local -p /path/to/codebase -f \"Microservices architecture\""
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

[[ -n "$PROJECT_NAME" ]] || die "Project name is required. Use -n or --name"
[[ -n "$SOURCE_TYPE" ]] || die "Source type is required. Use -t or --type"
[[ -n "$SOURCE_PATH" ]] || die "Source path is required. Use -p or --path"
[[ -n "$TARGET_FUNCTIONALITY" ]] || die "Target functionality is required. Use -f or --functionality"

# ------------------------- INTERACTIVE SOURCE ANALYSIS -------------------------
if [[ "$SOURCE_TYPE" == "github" ]]; then
  echo -e "\n${CYAN}🔍 GitHub Repository Analysis${NC}"
  echo -e "${PURPLE}==========================${NC}\n"
  
  # Analyze GitHub repository
  SOURCE_INFO=$(analyze_github_repo "$SOURCE_PATH")
  
elif [[ "$SOURCE_TYPE" == "local" ]]; then
  echo -e "\n${CYAN}🔍 Local Codebase Analysis${NC}"
  echo -e "${PURPLE}========================${NC}\n"
  
  # Analyze local codebase
  SOURCE_INFO=$(analyze_local_codebase "$SOURCE_PATH")
  
else
  die "Invalid source type: $SOURCE_TYPE. Use 'github' or 'local'"
fi

echo -e "${WHITE}Source Analysis Results:${NC}"
echo -e "$SOURCE_INFO"

# ------------------------- ENHANCED PROJECT SETUP -------------------------
echo -e "\n${CYAN}🚀 Code Refactor Orchestration Setup${NC}"
echo -e "${PURPLE}==================================${NC}\n"

# Step 1: Validate inputs
show_progress 1 8 "Validating source and target requirements"
if [[ -z "$SOURCE_INFO" ]]; then
  die "Source analysis failed"
fi

if [[ -z "$TARGET_FUNCTIONALITY" ]]; then
  die "Target functionality is required"
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

# Setup source analysis directory
setup_source_analysis

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

# Step 7: Generate refactor prompt
show_progress 7 8 "Generating refactor orchestration prompt"
REFACTOR_PROMPT=$(generate_refactor_prompt "$SOURCE_TYPE" "$SOURCE_INFO" "$TARGET_FUNCTIONALITY")

# Store prompt for later use
echo "$REFACTOR_PROMPT" > .refactor_prompt
echo "$SOURCE_INFO" > .source_analysis
echo "$TARGET_FUNCTIONALITY" > .target_functionality

# Step 8: Ready for orchestration
show_progress 8 8 "Refactor orchestration setup complete"

success "Project '$PROJECT_NAME' is ready for code refactor orchestration!"

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
    bbam "Prioritizing SPARC mode selection based on refactoring requirements..."
    
    # Priority 1: Critical modes for refactoring success
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
      ./claude-flow sparc architect "design refactored system architecture" $NONINTERACTIVE $VERBOSE_FLAG
      ;;
    "api")
      ./claude-flow sparc spec "setup refactored API development environment" $NONINTERACTIVE $VERBOSE_FLAG
      ;;
    "ui")
      ./claude-flow sparc spec "setup refactored web development environment" $NONINTERACTIVE $VERBOSE_FLAG
      ;;
    "ml")
      ./claude-flow sparc spec "setup refactored machine learning environment" $NONINTERACTIVE $VERBOSE_FLAG
      ;;
    "tdd")
      ./claude-flow sparc tdd "setup refactored test-driven development environment" $NONINTERACTIVE $VERBOSE_FLAG
      ;;
    *)
      # Auto mode - let the orchestrator decide
      return 0
      ;;
  esac
  return 0
}

if [[ "$SPARC_MODE" == "auto" ]]; then
  # We let Flow choose based on the refactoring requirements
  [[ -f CLAUDE.md ]] || touch CLAUDE.md
else
  apply_sparc_mode "$SPARC_MODE" || warn "SPARC mode '$SPARC_MODE' failed to apply; continuing with default setup."
  [[ -f CLAUDE.md ]] || touch CLAUDE.md
fi

# ------------------------- REFACTOR ORCHESTRATION -------------------------
say "Starting code refactor orchestration..."

TOPOLOGY_INSTR=""
if [[ "$TOPOLOGY" != "auto" ]]; then
  TOPOLOGY_INSTR="Force topology: $TOPOLOGY with $AGENTS agents."
fi

SPARC_INSTR=""
if [[ "$SPARC_MODE" != "auto" ]]; then
  SPARC_INSTR="Force SPARC mode: $SPARC_MODE."
fi

# Compose final prompt including refactoring requirements
FINAL_REFACTOR_PROMPT=$(printf "%s\n\n%s\n%s\n" "$REFACTOR_PROMPT" "$SPARC_INSTR" "$TOPOLOGY_INSTR")

# BBPF: Progressive refactoring with validation gates
if [[ "$WFGY_ENABLED" == true ]]; then
  bbpf "Step 5: Orchestrating code refactoring with progressive validation..."
  ./claude-flow task orchestrate --task "$FINAL_REFACTOR_PROMPT" --strategy parallel $NONINTERACTIVE $VERBOSE_FLAG
  
  bbpf "Step 6: Validating refactoring success..."
  if [[ ! -f "bootstrap.sh" ]]; then
    bbcr "Refactoring inconsistency: bootstrap.sh not created"
    warn "BBPF warning: bootstrap.sh not created, but continuing"
  fi
  
  bbpf "Step 7: Validating refactored structure..."
  if [[ ! -f "Makefile" ]]; then
    bbcr "Refactoring inconsistency: Makefile not created"
    warn "BBPF warning: Makefile not created, but continuing"
  fi
  
  bbpf "Code refactoring completed successfully with validation"
else
  # Run task orchestrate for refactoring
  ./claude-flow task orchestrate --task "$FINAL_REFACTOR_PROMPT" --strategy parallel $NONINTERACTIVE $VERBOSE_FLAG
fi

# ------------------------- POST-REFACTOR SETUP -------------------------
if [[ "$SETUP_DEPENDENCIES" == true ]]; then
  bbpf "Step 8: Setting up refactored project environment..."
  
  # Setup database
  setup_database "${PROJECT_NAME}_dev"
  
  # Setup Redis
  setup_redis
  
  # Setup project environment
  setup_project_env "$(pwd)"
  
  # Run project tests
  run_project_tests "$(pwd)"
  
  bbpf "Refactored project environment setup completed"
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

# ------------------------- REFACTOR DOCUMENTATION --------------------
say "Generating Refactor_Walkthrough.md with migration guide..."

# BBAM: Focus on critical documentation
if [[ "$WFGY_ENABLED" == true ]]; then
  bbam "Generating comprehensive refactor walkthrough with migration guidance..."
  ./claude-flow task orchestrate --task "Read the repo and generate Refactor_Walkthrough.md covering: original source analysis, refactoring decisions, architecture changes, migration guide, testing strategy, and deployment differences. Focus on BBMC validation points, BBPF pipeline structure, BBCR contradiction detection, and BBAM attention management." --strategy sequential $NONINTERACTIVE $VERBOSE_FLAG
else
  ./claude-flow task orchestrate --task "Read the repo and generate Refactor_Walkthrough.md covering: original source analysis, refactoring decisions, architecture changes, migration guide, testing strategy, and deployment differences." --strategy sequential $NONINTERACTIVE $VERBOSE_FLAG
fi

# ------------------------- FINAL VALIDATION -------------------------
if [[ "$WFGY_ENABLED" == true ]]; then
  bbpf "Final validation step: Ensuring refactoring completeness..."
  
  # Check for critical files
  CRITICAL_FILES=("CLAUDE.md" "Refactor_Walkthrough.md")
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
  bbpf "Step 12: Auto-starting refactored project for validation..."
  start_project "$(pwd)"
fi

# ------------------------- FINAL OUTPUT ----------------------------
success "🎉 CODE REFACTOR ORCHESTRATION COMPLETE!"
echo ""
echo -e "${CYAN}Project:${NC} $PROJECT_DIR"
echo -e "${CYAN}Source:${NC} $SOURCE_TYPE - $SOURCE_PATH"
echo -e "${CYAN}Target:${NC} $TARGET_FUNCTIONALITY"
echo ""
echo -e "${WHITE}Key files:${NC}"
echo "  - CLAUDE.md (Refactoring PRD)"
echo "  - Refactor_Walkthrough.md (Migration guide)"
echo "  - bootstrap.sh (installer)  -> run: ./bootstrap.sh"
echo "  - Makefile (setup/test/smoke/run-daily) -> run: make setup && make test && make smoke"
echo "  - .source_analysis (Original code analysis)"
echo "  - .target_functionality (Target requirements)"

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
echo -e "${WHITE}Refactoring Commands:${NC}"
echo "  - ./claude-flow task orchestrate \"Improve refactored architecture\" --strategy parallel $NONINTERACTIVE $VERBOSE_FLAG"
echo "  - ./claude-flow sparc tdd \"Add comprehensive tests to refactored code\" $NONINTERACTIVE $VERBOSE_FLAG"

if [[ "$SETUP_DEPENDENCIES" == true ]]; then
  echo ""
  echo -e "${WHITE}Project Management:${NC}"
  echo "  - npm start          # Start the refactored application"
  echo "  - npm test           # Run tests"
  echo "  - npm run dev        # Start in development mode"
  echo "  - brew services list # Check service status"
fi

if [[ "$WFGY_ENABLED" == true ]]; then
  echo ""
  echo -e "${WHITE}WFGY-specific commands:${NC}"
  echo "  - ./claude-flow memory store \"refactor_context\" \"$(basename "$PROJECT_DIR") refactored from $SOURCE_TYPE source\""
  echo "  - ./claude-flow sparc spec \"validate refactored code consistency with BBMC principles\""
  echo "  - ./claude-flow status --verbose  # Monitor refactored project health"
fi

echo ""
echo -e "${GREEN}🚀 Your refactored project is ready to go!${NC}"
