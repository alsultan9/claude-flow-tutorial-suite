#!/bin/bash

# 07_simple_refactor.sh - Simple Code Refactor Orchestrator (No TUI)
# Transform existing codebases into new applications using Claude Flow

set -euo pipefail

# ------------------------- CONFIGURATION -------------------------
PROJECT_NAME=""
SOURCE_TYPE=""
SOURCE_PATH=""
TARGET_FUNCTIONALITY=""
WFGY_ENABLED=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ------------------------- HELPER FUNCTIONS -------------------------
say() {
  echo -e "${BLUE}[simple-refactor]${NC} $*"
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

# WFGY Functions
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

# Function to analyze source code
analyze_source() {
  local source_path="$1"
  local source_type="$2"
  
  say "Analyzing source: $source_path"
  
  if [[ "$source_type" == "github" ]]; then
    # Clone and analyze GitHub repo
    local repo_name=$(basename "$source_path" .git)
    git clone "$source_path" "temp_analysis/$repo_name" >/dev/null 2>&1 || true
    source_path="temp_analysis/$repo_name"
  fi
  
  # Detect language
  local language="Unknown"
  if [[ -f "$source_path/package.json" ]]; then
    language="JavaScript/Node.js"
  elif [[ -f "$source_path/requirements.txt" ]] || [[ -f "$source_path/Pipfile" ]]; then
    language="Python"
  elif [[ -f "$source_path/Cargo.toml" ]]; then
    language="Rust"
  elif [[ -f "$source_path/go.mod" ]]; then
    language="Go"
  elif [[ -f "$source_path/pom.xml" ]]; then
    language="Java"
  fi
  
  # Detect architecture
  local architecture="Monolithic"
  if [[ -d "$source_path/src" ]] && [[ -d "$source_path/tests" ]]; then
    architecture="Standard (src/tests)"
  elif [[ -f "$source_path/docker-compose.yml" ]]; then
    architecture="Microservices (Docker)"
  elif [[ -d "$source_path/frontend" ]] && [[ -d "$source_path/backend" ]]; then
    architecture="Full-stack (frontend/backend)"
  elif [[ -f "$source_path/serverless.yml" ]]; then
    architecture="Serverless"
  fi
  
  echo "Language: $language"
  echo "Architecture: $architecture"
  echo "Source Path: $source_path"
}

# Function to generate refactor prompt
generate_prompt() {
  local source_info="$1"
  local target_functionality="$2"
  
  cat << EOF
You are a Code Refactor Orchestrator. Transform the existing codebase into a new application.

SOURCE ANALYSIS:
$source_info

TARGET FUNCTIONALITY:
$target_functionality

REQUIREMENTS:
1. Analyze the source code thoroughly
2. Identify reusable components and patterns
3. Design a new architecture that combines the best elements
4. Implement the new application with modern best practices
5. Ensure the new application is production-ready
6. Provide clear documentation and migration guide

CONSTRAINTS:
- Maintain the core functionality while improving architecture
- Use modern development practices and tools
- Ensure scalability and maintainability
- Provide comprehensive testing
- Include deployment configuration

OUTPUT:
1. Complete new application codebase
2. Architecture documentation
3. Migration guide from source to target
4. Testing suite
5. Deployment configuration
6. Performance optimization recommendations

Rules:
- Non-interactive; do not ask questions
- Create all files in the current directory
- Apply BBMC validation at each step
- Use BBPF progressive approach
- Implement BBCR contradiction detection
- Apply BBAM attention management
EOF
}

# ------------------------- PARSE ARGUMENTS -------------------------
while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--name)
      PROJECT_NAME="$2"
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
    -h|--help)
      echo "Usage: $0 -n PROJECT_NAME -t SOURCE_TYPE -p SOURCE_PATH -f TARGET_FUNCTIONALITY"
      echo "  -n, --name NAME       Project name (required)"
      echo "  -t, --type TYPE       Source type: github, local (required)"
      echo "  -p, --path PATH       Source path (required)"
      echo "  -f, --functionality   Target functionality description (required)"
      echo "  --no-wfgy            Disable WFGY methodology"
      echo ""
      echo "Examples:"
      echo "  $0 -n modern-app -t github -p https://github.com/user/repo.git -f \"Modern React app\""
      echo "  $0 -n local-adaptation -t local -p /path/to/code -f \"Microservices architecture\""
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

# ------------------------- MAIN EXECUTION -------------------------
echo -e "\n${CYAN}🔄 Simple Code Refactor Orchestrator${NC}"
echo -e "${PURPLE}==================================${NC}\n"

# BBMC: Validate inputs
bbmc "Validating source and target requirements"
if [[ "$SOURCE_TYPE" != "github" ]] && [[ "$SOURCE_TYPE" != "local" ]]; then
  die "Invalid source type: $SOURCE_TYPE. Use 'github' or 'local'"
fi

if [[ "$SOURCE_TYPE" == "local" ]] && [[ ! -d "$SOURCE_PATH" ]]; then
  die "Local source path does not exist: $SOURCE_PATH"
fi

# BBPF: Step 1 - Analyze source
bbpf "Step 1: Analyzing source code"
SOURCE_INFO=$(analyze_source "$SOURCE_PATH" "$SOURCE_TYPE")
echo -e "${WHITE}Source Analysis:${NC}"
echo "$SOURCE_INFO"

# BBPF: Step 2 - Create project directory
bbpf "Step 2: Creating project structure"
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# BBPF: Step 3 - Generate refactor prompt
bbpf "Step 3: Generating refactor orchestration prompt"
REFACTOR_PROMPT=$(generate_prompt "$SOURCE_INFO" "$TARGET_FUNCTIONALITY")
echo "$REFACTOR_PROMPT" > .refactor_prompt

# BBAM: Focus on critical components
bbam "Focusing on critical refactoring components"

# BBPF: Step 4 - Execute refactoring with Claude Flow
bbpf "Step 4: Executing refactoring with Claude Flow"
say "Starting refactoring process..."

# Use npx directly to avoid TUI
npx claude-flow@alpha sparc architect "$REFACTOR_PROMPT" --non-interactive --verbose

# BBCR: Check for contradictions
bbcr "Checking for refactoring contradictions"
if [[ ! -f "README.md" ]] && [[ ! -f "package.json" ]] && [[ ! -f "requirements.txt" ]]; then
  warn "BBCR: No standard project files created - refactoring may have failed"
fi

# BBPF: Step 5 - Generate documentation
bbpf "Step 5: Generating documentation"
if [[ "$WFGY_ENABLED" == true ]]; then
  npx claude-flow@alpha sparc documenter "Generate comprehensive documentation including: architecture overview, migration guide, API documentation, and deployment instructions" --non-interactive --verbose
else
  npx claude-flow@alpha sparc documenter "Generate project documentation" --non-interactive --verbose
fi

# Final validation
bbpf "Final validation step"
CRITICAL_FILES=("README.md")
for file in "${CRITICAL_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    bbcr "Final validation inconsistency: $file not found"
    warn "BBPF warning: Critical file $file missing"
  fi
done

# Success output
success "🎉 CODE REFACTOR ORCHESTRATION COMPLETE!"
echo ""
echo -e "${CYAN}Project:${NC} $(pwd)"
echo -e "${CYAN}Source:${NC} $SOURCE_TYPE - $SOURCE_PATH"
echo -e "${CYAN}Target:${NC} $TARGET_FUNCTIONALITY"
echo ""
echo -e "${WHITE}Key files:${NC}"
ls -la | grep -E "\.(md|json|py|js|ts|yml|yaml)$" | head -10
echo ""
echo -e "${WHITE}Next steps:${NC}"
echo "  1. Review the generated code"
echo "  2. Test the application"
echo "  3. Deploy to your environment"
echo ""
echo -e "${GREEN}🚀 Your refactored project is ready!${NC}"
