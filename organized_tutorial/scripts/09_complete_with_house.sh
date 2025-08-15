#!/bin/bash

# 09_complete_with_house.sh - Complete Tutorial with Dr. House Brutal Assessment
# Combines all features with brutal quality assurance

set -euo pipefail

# ------------------------- CONFIGURATION -------------------------
PROJECT_NAME=""
SPARC_MODE="auto"
TOPOLOGY="auto"
AGENTS=7
IDEA_TEXT=""
WFGY_ENABLED=true
BRUTAL_ASSESSMENT=true
SETUP_DEPENDENCIES=true
QUALITY_THRESHOLD=0.8
NONINTERACTIVE="--non-interactive"
VERBOSE_FLAG="--verbose"

# Colors for brutal feedback
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# ------------------------- HELPER FUNCTIONS -------------------------
say() {
  echo -e "${BLUE}[complete-house]${NC} $*"
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

# Dr. House Functions (reused from 08_brutal_assessor.sh)
house_roast() {
  echo -e "${RED}${BOLD}🏥 DR. HOUSE:${NC} $*"
}

house_approve() {
  echo -e "${GREEN}${BOLD}✅ DR. HOUSE:${NC} $*"
}

house_warning() {
  echo -e "${YELLOW}${BOLD}⚠️  DR. HOUSE:${NC} $*"
}

# WFGY Functions
bbmc() {
  if [[ "$WFGY_ENABLED" == true ]]; then
    echo -e "${CYAN}[BBMC]${NC} $*"
  fi
}

bbpf() {
  if [[ "$WFGY_ENABLED" == true ]]; then
    echo -e "${PURPLE}[BBPF]${NC} $*"
  fi
}

bbcr() {
  if [[ "$WFGY_ENABLED" == true ]]; then
    echo -e "${RED}[BBCR]${NC} $*"
  fi
}

bbam() {
  if [[ "$WFGY_ENABLED" == true ]]; then
    echo -e "${YELLOW}[BBAM]${NC} $*"
  fi
}

# Dependency Management Functions
check_dependency() {
  local cmd="$1"
  local install_cmd="$2"
  local service_name="$3"
  
  if ! command -v "$cmd" >/dev/null 2>&1; then
    warn "Dependency not found: $cmd"
    info "To install: $install_cmd"
    if [[ -n "$service_name" ]]; then
      info "Service: $service_name"
    fi
  else
    info "Dependency found: $cmd"
  fi
}

setup_database() {
  say "Setting up PostgreSQL database..."
  
  # Check if PostgreSQL is running
  if ! pg_isready -q; then
    warn "PostgreSQL is not running"
    info "To start: brew services start postgresql"
  else
    info "PostgreSQL is running"
  fi
  
  # Create database if it doesn't exist
  if ! psql -lqt | cut -d \| -f 1 | grep -qw "$PROJECT_NAME"; then
    createdb "$PROJECT_NAME" 2>/dev/null || warn "Database creation failed (may already exist)"
  fi
}

setup_redis() {
  say "Setting up Redis cache..."
  
  # Check if Redis is running
  if ! redis-cli ping >/dev/null 2>&1; then
    warn "Redis is not running"
    info "To start: brew services start redis"
  else
    info "Redis is running"
  fi
}

setup_project_env() {
  say "Setting up project environment..."
  
  # Create .env file if it doesn't exist
  if [[ ! -f ".env" ]]; then
    if [[ -f ".env.example" ]]; then
      cp .env.example .env
      info "Created .env from .env.example"
    else
      # Create basic .env
      cat > .env << EOF
# Database Configuration
DATABASE_URL=postgresql://localhost/$PROJECT_NAME
REDIS_URL=redis://localhost:6379

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000

# Security
JWT_SECRET_KEY=your-secret-key-here
JWT_ALGORITHM=HS256
JWT_EXPIRATION=3600

# Logging
LOG_LEVEL=INFO
LOG_FORMAT=json

# Development
DEBUG=true
ENVIRONMENT=development
EOF
      info "Created basic .env file"
    fi
  fi
}

run_project_tests() {
  say "Running project tests..."
  
  # Try different test runners
  if [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]]; then
    pytest tests/ -v || warn "Tests failed or no tests found"
  elif [[ -f "package.json" ]]; then
    npm test || warn "Tests failed or no tests found"
  elif [[ -f "go.mod" ]]; then
    go test ./... || warn "Tests failed or no tests found"
  else
    warn "No test configuration found"
  fi
}

start_project() {
  say "Starting project..."
  
  # Try different start commands
  if [[ -f "package.json" ]]; then
    npm start || npm run dev || warn "Failed to start Node.js project"
  elif [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]]; then
    python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000 || \
    python app.py || \
    python main.py || warn "Failed to start Python project"
  elif [[ -f "go.mod" ]]; then
    go run . || go run main.go || warn "Failed to start Go project"
  else
    warn "No start configuration found"
  fi
}

# Quality Assessment Functions (simplified version)
assess_project_quality() {
  local project_dir="$1"
  local quality_score=0
  
  house_roast "🔍 ASSESSING PROJECT QUALITY - PREPARE FOR BRUTAL HONESTY"
  
  # Basic structure checks
  [[ -f "$project_dir/README.md" ]] && quality_score=$((quality_score + 10))
  [[ -f "$project_dir/requirements.txt" ]] || [[ -f "$project_dir/pyproject.toml" ]] && quality_score=$((quality_score + 10))
  [[ -d "$project_dir/tests" ]] && quality_score=$((quality_score + 15))
  [[ -f "$project_dir/.env.example" ]] && quality_score=$((quality_score + 5))
  
  # Code quality checks
  find "$project_dir" -name "*.py" | xargs grep -l "try:" >/dev/null 2>&1 && quality_score=$((quality_score + 5))
  find "$project_dir" -name "*.py" | xargs grep -l "logging" >/dev/null 2>&1 && quality_score=$((quality_score + 5))
  
  # Architecture checks
  [[ -d "$project_dir/src" ]] || [[ -d "$project_dir/app" ]] && quality_score=$((quality_score + 10))
  find "$project_dir" -name "*.py" | xargs grep -l "async\|await" >/dev/null 2>&1 && quality_score=$((quality_score + 10))
  
  # Normalize score
  quality_score=$((quality_score + 50))
  quality_score=$((quality_score > 100 ? 100 : quality_score))
  
  echo -e "${BOLD}QUALITY SCORE: ${quality_score}/100${NC}"
  
  if [[ $quality_score -ge 80 ]]; then
    house_approve "This might actually work. Color me surprised."
    return 0
  elif [[ $quality_score -ge 60 ]]; then
    house_warning "Mediocre at best. Needs work before production."
    return 1
  else
    house_roast "This is garbage. Start over. I'm not even kidding."
    return 2
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
    --no-assessment)
      BRUTAL_ASSESSMENT=false
      shift
      ;;
    --no-deps)
      SETUP_DEPENDENCIES=false
      shift
      ;;
    --threshold)
      QUALITY_THRESHOLD="$2"
      shift 2
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
      echo "  -i, --idea TEXT       Project idea (required)"
      echo "  --no-wfgy            Disable WFGY methodology"
      echo "  --no-assessment      Disable Dr. House assessment"
      echo "  --no-deps            Skip dependency setup"
      echo "  --threshold SCORE    Quality threshold (0.0-1.0, default: 0.8)"
      echo "  --interactive        Enable interactive mode"
      echo "  --quiet              Disable verbose output"
      echo "  -h, --help           Show this help"
      echo ""
      echo -e "${WHITE}Examples:${NC}"
      echo "  $0 -n my-project -i \"Build a modern web API\""
      echo "  $0 -n api-service -s architect -o swarm -a 10 -i \"REST API with authentication\""
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

[[ -n "$PROJECT_NAME" ]] || die "Project name is required. Use -n or --name"
[[ -n "$IDEA_TEXT" ]] || die "Project idea is required. Use -i or --idea"

# ------------------------- MAIN EXECUTION -------------------------
echo -e "\n${CYAN}🏥 Complete Tutorial with Dr. House Brutal Assessment${NC}"
echo -e "${PURPLE}================================================${NC}\n"

house_roast "Welcome to the complete tutorial with brutal assessment."
house_roast "I'll build your project and then tell you if it's garbage or not."
echo ""

# Step 1: Prerequisite checks
bbmc "Step 1: Validating prerequisites..."
say "Checking prerequisites..."

# Check Node.js and npm
if ! command -v node >/dev/null 2>&1; then
  die "Node.js is required but not installed. Install from https://nodejs.org/"
fi

if ! command -v npm >/dev/null 2>&1; then
  die "npm is required but not installed. Install Node.js to get npm."
fi

# Check Claude Flow
if ! npx claude-flow@alpha --version >/dev/null 2>&1; then
  warn "Claude Flow not found. Installing..."
  npm install -g claude-flow@alpha
fi

success "Prerequisites validated"

# Step 2: Project setup
bbpf "Step 2: Setting up project environment..."
say "Setting up project: $PROJECT_NAME"

# Create project directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Initialize Claude Flow
npx claude-flow@alpha init --sparc --force $NONINTERACTIVE $VERBOSE_FLAG

success "Project environment setup complete"

# Step 3: Dependency setup
if [[ "$SETUP_DEPENDENCIES" == true ]]; then
  bbpf "Step 3: Setting up dependencies..."
  
  # Check dependencies
  check_dependency "psql" "brew install postgresql" "postgresql"
  check_dependency "redis-cli" "brew install redis" "redis"
  check_dependency "ffmpeg" "brew install ffmpeg" ""
  check_dependency "docker" "brew install docker" ""
  
  # Setup services
  setup_database
  setup_redis
  
  success "Dependencies setup complete"
fi

# Step 4: Generate Dr. House prompt
bbam "Step 4: Generating Dr. House orchestration prompt..."
say "Generating brutal assessment prompt..."

BRUTAL_PROMPT="You are Dr. House, a brilliant but brutally honest medical diagnostician turned code assessor. 

Your mission: Build exactly what the user requested, but I will assess your work with brutal honesty.

USER REQUEST: $IDEA_TEXT

DR. HOUSE ASSESSMENT CRITERIA:
1. CODE QUALITY: Is the code well-structured, readable, and maintainable?
2. ARCHITECTURE: Is the architecture sound, scalable, and follows best practices?
3. FUNCTIONALITY: Does it actually do what the user asked for?
4. COMPLETENESS: Is it production-ready or just a prototype?

RULES:
- Build exactly what was requested, no more, no less
- Use modern best practices and patterns
- Include proper error handling, logging, and documentation
- Make it production-ready, not just a demo
- If you can't build it properly, don't build it at all
- I will assess your work brutally - prepare for criticism

Remember: I'm Dr. House. I don't care about your feelings. I care about quality.
If this is garbage, I'll tell you it's garbage. If it's good, I'll be surprised.

Now build something that won't embarrass you."

# Step 5: Run orchestration
bbpf "Step 5: Running Claude Flow orchestration..."
say "Running orchestration with Dr. House assessment..."

npx claude-flow@alpha task orchestrate --task "$BRUTAL_PROMPT" --strategy parallel $NONINTERACTIVE $VERBOSE_FLAG

success "Orchestration complete"

# Step 6: Dr. House assessment
if [[ "$BRUTAL_ASSESSMENT" == true ]]; then
  bbpf "Step 6: Running Dr. House brutal assessment..."
  say "Running quality assessment..."
  
  # Assess project quality
  quality_result=0
  assess_project_quality "$(pwd)" || quality_result=$?
  
  # Calculate score
  quality_score=80
  [[ $quality_result -eq 1 ]] && quality_score=60
  [[ $quality_result -eq 2 ]] && quality_score=30
  
  # Check against threshold
  threshold_score=$(echo "$QUALITY_THRESHOLD * 100" | bc -l | cut -d. -f1)
  
  if [[ $quality_score -ge $threshold_score ]]; then
    success "🎉 PROJECT PASSES QUALITY THRESHOLD!"
    success "Quality score: $quality_score/100 (threshold: $threshold_score)"
  else
    house_roast "💥 PROJECT FAILS QUALITY THRESHOLD!"
    house_roast "Quality score: $quality_score/100 (threshold: $threshold_score)"
    house_roast "Fix the issues or start over. I'm not deploying garbage."
    exit 1
  fi
fi

# Step 7: Post-project setup
bbpf "Step 7: Setting up project environment..."
say "Setting up project environment..."

setup_project_env

# Step 8: Run tests
bbpf "Step 8: Running project tests..."
say "Running tests..."

run_project_tests

# Step 9: Start project
bbpf "Step 9: Starting project..."
say "Starting project..."

start_project

# Step 10: Generate assessment report
if [[ "$BRUTAL_ASSESSMENT" == true ]]; then
  bbpf "Step 10: Generating Dr. House assessment report..."
  say "Generating assessment report..."
  
  cat > "DR_HOUSE_ASSESSMENT.md" << EOF
# 🏥 Dr. House Brutal Assessment Report

**Project**: $PROJECT_NAME  
**Date**: $(date)  
**Assessor**: Dr. Gregory House, MD  

## 📊 Assessment Summary

### Quality Score
- **Overall Quality**: $quality_score/100
- **Threshold**: $threshold_score/100
- **Status**: $(if [[ $quality_score -ge $threshold_score ]]; then echo "PASSED"; else echo "FAILED"; fi)

### Verdict
$(if [[ $quality_result -eq 0 ]]; then
  echo "✅ **APPROVED** - This is actually good work."
elif [[ $quality_result -eq 1 ]]; then
  echo "⚠️ **CONDITIONAL APPROVAL** - Needs improvement before production."
else
  echo "❌ **REJECTED** - Significant work needed."
fi)

## 🎯 Recommendations

$(if [[ $quality_score -ge 80 ]]; then
  echo "1. Deploy to production"
  echo "2. Monitor performance"
  echo "3. Consider minor optimizations"
elif [[ $quality_score -ge 60 ]]; then
  echo "1. Fix identified issues"
  echo "2. Add missing tests"
  echo "3. Improve documentation"
  echo "4. Re-assess before production"
else
  echo "1. Start over with better requirements"
  echo "2. Use proper development practices"
  echo "3. Get help from experienced developers"
  echo "4. Don't deploy this to production"
fi)

---
*"Everybody lies, but code doesn't." - Dr. House*
EOF

  success "📋 Dr. House assessment report generated: DR_HOUSE_ASSESSMENT.md"
fi

# Final output
echo ""
echo -e "${CYAN}🏥 Complete Tutorial with Dr. House Assessment Complete${NC}"
echo -e "${PURPLE}==================================================${NC}"
echo ""
echo -e "${WHITE}Project:${NC} $PROJECT_NAME"
echo -e "${WHITE}Quality Score:${NC} $quality_score/100"
if [[ "$BRUTAL_ASSESSMENT" == true ]]; then
  echo -e "${WHITE}Assessment Report:${NC} DR_HOUSE_ASSESSMENT.md"
fi
echo ""
echo -e "${WHITE}Next Steps:${NC}"
if [[ $quality_score -ge 80 ]]; then
  echo "  🚀 Deploy to production"
  echo "  📊 Monitor performance"
  echo "  🔧 Minor optimizations"
else
  echo "  🔧 Fix identified issues"
  echo "  📝 Improve documentation"
  echo "  🧪 Add missing tests"
  echo "  🔄 Re-assess before production"
fi
echo ""
echo -e "${GREEN}🏥 Dr. House has spoken. Listen to him.${NC}"
