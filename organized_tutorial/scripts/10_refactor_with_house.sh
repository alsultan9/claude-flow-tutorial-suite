#!/bin/bash

# 10_refactor_with_house.sh - Code Refactor with Dr. House Brutal Assessment
# Refactors existing codebases with brutal quality assurance

set -euo pipefail

# ------------------------- CONFIGURATION -------------------------
PROJECT_NAME=""
SOURCE_TYPE=""
SOURCE_PATH=""
TARGET_FUNCTIONALITY=""
WFGY_ENABLED=true
BRUTAL_ASSESSMENT=true
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
  echo -e "${BLUE}[refactor-house]${NC} $*"
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

# Dr. House Functions
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

# Source Analysis Functions
analyze_github_repo() {
  local repo_url="$1"
  local repo_name=$(basename "$repo_url" .git)
  
  say "Analyzing GitHub repository: $repo_url"
  
  # Create analysis directory
  mkdir -p "source_analysis"
  
  # Clone repository if not exists
  if [[ ! -d "source_analysis/$repo_name" ]]; then
    git clone "$repo_url" "source_analysis/$repo_name" >/dev/null 2>&1
  fi
  
  local repo_path="source_analysis/$repo_name"
  
  # Detect language
  local language="unknown"
  if [[ -f "$repo_path/package.json" ]]; then
    language="javascript"
  elif [[ -f "$repo_path/requirements.txt" ]] || [[ -f "$repo_path/pyproject.toml" ]]; then
    language="python"
  elif [[ -f "$repo_path/go.mod" ]]; then
    language="go"
  elif [[ -f "$repo_path/Cargo.toml" ]]; then
    language="rust"
  fi
  
  # Detect architecture
  local architecture="monolithic"
  if [[ -d "$repo_path/src" ]] || [[ -d "$repo_path/app" ]]; then
    architecture="modular"
  fi
  
  # Detect features
  local features=()
  [[ -f "$repo_path/package.json" ]] && features+=("nodejs")
  [[ -f "$repo_path/requirements.txt" ]] && features+=("python")
  [[ -d "$repo_path/tests" ]] && features+=("tests")
  [[ -f "$repo_path/Dockerfile" ]] && features+=("docker")
  [[ -f "$repo_path/.github/workflows" ]] && features+=("ci/cd")
  
  # Save analysis
  cat > ".source_analysis" << EOF
Language: $language
Architecture: $architecture
Features: ${features[*]}
Source Path: $repo_path
Source Type: github
EOF
  
  echo "Language: $language"
  echo "Architecture: $architecture"
  echo "Features: ${features[*]}"
  echo "Source Path: $repo_path"
}

analyze_local_codebase() {
  local codebase_path="$1"
  
  say "Analyzing local codebase: $codebase_path"
  
  if [[ ! -d "$codebase_path" ]]; then
    die "Local codebase path does not exist: $codebase_path"
  fi
  
  # Detect language
  local language="unknown"
  if [[ -f "$codebase_path/package.json" ]]; then
    language="javascript"
  elif [[ -f "$codebase_path/requirements.txt" ]] || [[ -f "$codebase_path/pyproject.toml" ]]; then
    language="python"
  elif [[ -f "$codebase_path/go.mod" ]]; then
    language="go"
  elif [[ -f "$codebase_path/Cargo.toml" ]]; then
    language="rust"
  fi
  
  # Detect architecture
  local architecture="monolithic"
  if [[ -d "$codebase_path/src" ]] || [[ -d "$codebase_path/app" ]]; then
    architecture="modular"
  fi
  
  # Detect features
  local features=()
  [[ -f "$codebase_path/package.json" ]] && features+=("nodejs")
  [[ -f "$codebase_path/requirements.txt" ]] && features+=("python")
  [[ -d "$codebase_path/tests" ]] && features+=("tests")
  [[ -f "$codebase_path/Dockerfile" ]] && features+=("docker")
  [[ -d "$codebase_path/.github" ]] && features+=("ci/cd")
  
  # Save analysis
  cat > ".source_analysis" << EOF
Language: $language
Architecture: $architecture
Features: ${features[*]}
Source Path: $codebase_path
Source Type: local
EOF
  
  echo "Language: $language"
  echo "Architecture: $architecture"
  echo "Features: ${features[*]}"
  echo "Source Path: $codebase_path"
}

# Quality Assessment Functions
assess_refactor_quality() {
  local project_dir="$1"
  local source_info="$2"
  local target_functionality="$3"
  
  house_roast "🔍 ASSESSING REFACTOR QUALITY - DID THEY ACTUALLY IMPROVE ANYTHING?"
  
  local quality_score=0
  local issues=()
  local improvements=()
  
  # Load source analysis
  if [[ -f ".source_analysis" ]]; then
    source .source_analysis
  fi
  
  # Check if refactoring actually happened
  if [[ -f "$project_dir/README.md" ]]; then
    improvements+=("README.md created")
    quality_score=$((quality_score + 5))
  fi
  
  # Check for modern structure
  if [[ -d "$project_dir/src" ]] || [[ -d "$project_dir/app" ]]; then
    improvements+=("Modular structure implemented")
    quality_score=$((quality_score + 15))
  else
    issues+=("Still monolithic - No architectural improvement")
    quality_score=$((quality_score - 10))
  fi
  
  # Check for modern dependencies
  if [[ -f "$project_dir/pyproject.toml" ]] || [[ -f "$project_dir/package.json" ]]; then
    improvements+=("Modern dependency management")
    quality_score=$((quality_score + 10))
  else
    issues+=("No modern dependency management")
    quality_score=$((quality_score - 5))
  fi
  
  # Check for tests
  if [[ -d "$project_dir/tests" ]] || find "$project_dir" -name "*test*.py" | grep -q .; then
    improvements+=("Tests implemented")
    quality_score=$((quality_score + 15))
  else
    issues+=("No tests - Still amateur hour")
    quality_score=$((quality_score - 15))
  fi
  
  # Check for documentation
  if find "$project_dir" -name "*.md" | grep -q .; then
    improvements+=("Documentation added")
    quality_score=$((quality_score + 10))
  else
    issues+=("No documentation - Hope you like debugging")
    quality_score=$((quality_score - 10))
  fi
  
  # Check for configuration management
  if [[ -f "$project_dir/.env.example" ]] || [[ -f "$project_dir/config.py" ]]; then
    improvements+=("Configuration management")
    quality_score=$((quality_score + 5))
  else
    issues+=("No configuration management")
    quality_score=$((quality_score - 5))
  fi
  
  # Check for error handling
  if find "$project_dir" -name "*.py" | xargs grep -l "try:" >/dev/null 2>&1; then
    improvements+=("Error handling implemented")
    quality_score=$((quality_score + 5))
  else
    issues+=("No error handling - Hope nothing breaks")
    quality_score=$((quality_score - 5))
  fi
  
  # Check for logging
  if find "$project_dir" -name "*.py" | xargs grep -l "logging" >/dev/null 2>&1; then
    improvements+=("Logging implemented")
    quality_score=$((quality_score + 5))
  else
    issues+=("No logging - Good luck troubleshooting")
    quality_score=$((quality_score - 5))
  fi
  
  # Check if target functionality was implemented
  if [[ -n "$target_functionality" ]]; then
    local target_lower=$(echo "$target_functionality" | tr '[:upper:]' '[:lower:]')
    
    if echo "$target_lower" | grep -q "api\|rest\|web" && find "$project_dir" -name "*.py" | xargs grep -l "FastAPI\|flask\|django" | grep -q .; then
      improvements+=("API functionality implemented")
      quality_score=$((quality_score + 20))
    elif echo "$target_lower" | grep -q "api\|rest\|web"; then
      issues+=("Requested API but not implemented")
      quality_score=$((quality_score - 20))
    fi
    
    if echo "$target_lower" | grep -q "database\|db\|data" && find "$project_dir" -name "*.py" | xargs grep -l "sqlalchemy\|django.db" | grep -q .; then
      improvements+=("Database functionality implemented")
      quality_score=$((quality_score + 15))
    elif echo "$target_lower" | grep -q "database\|db\|data"; then
      issues+=("Requested database but not implemented")
      quality_score=$((quality_score - 15))
    fi
  fi
  
  # Normalize score
  quality_score=$((quality_score + 50))
  quality_score=$((quality_score > 100 ? 100 : quality_score))
  quality_score=$((quality_score < 0 ? 0 : quality_score))
  
  echo -e "${BOLD}REFACTOR QUALITY SCORE: ${quality_score}/100${NC}"
  echo ""
  
  if [[ ${#improvements[@]} -gt 0 ]]; then
    house_approve "IMPROVEMENTS MADE:"
    for improvement in "${improvements[@]}"; do
      echo -e "${GREEN}  ✅ $improvement${NC}"
    done
    echo ""
  fi
  
  if [[ ${#issues[@]} -gt 0 ]]; then
    house_roast "ISSUES FOUND:"
    for issue in "${issues[@]}"; do
      echo -e "${RED}  ❌ $issue${NC}"
    done
    echo ""
  fi
  
  if [[ $quality_score -ge 80 ]]; then
    house_approve "Actually improved the code. I'm impressed."
    return 0
  elif [[ $quality_score -ge 60 ]]; then
    house_warning "Some improvements made, but could be better."
    return 1
  else
    house_roast "This refactoring is garbage. They made it worse."
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
    --no-assessment)
      BRUTAL_ASSESSMENT=false
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
      echo "  -t, --type TYPE       Source type: github, local (required)"
      echo "  -p, --path PATH       Source path: URL or local path (required)"
      echo "  -f, --functionality   Target functionality description (required)"
      echo "  --no-wfgy            Disable WFGY methodology"
      echo "  --no-assessment      Disable Dr. House assessment"
      echo "  --threshold SCORE    Quality threshold (0.0-1.0, default: 0.8)"
      echo "  --interactive        Enable interactive mode"
      echo "  --quiet              Disable verbose output"
      echo "  -h, --help           Show this help"
      echo ""
      echo -e "${WHITE}Examples:${NC}"
      echo "  $0 -n refactored-app -t github -p https://github.com/user/repo.git -f \"Modern Python API\""
      echo "  $0 -n modern-app -t local -p /path/to/old/code -f \"React frontend with Node.js backend\""
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
echo -e "\n${CYAN}🏥 Code Refactor with Dr. House Brutal Assessment${NC}"
echo -e "${PURPLE}==============================================${NC}\n"

house_roast "Welcome to the brutal refactoring assessment."
house_roast "I'll refactor your code and then tell you if it's actually better or just different garbage."
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

# Step 2: Source analysis
bbpf "Step 2: Analyzing source code..."
say "Analyzing source: $SOURCE_TYPE - $SOURCE_PATH"

if [[ "$SOURCE_TYPE" == "github" ]]; then
  analyze_github_repo "$SOURCE_PATH"
elif [[ "$SOURCE_TYPE" == "local" ]]; then
  analyze_local_codebase "$SOURCE_PATH"
else
  die "Invalid source type: $SOURCE_TYPE (use 'github' or 'local')"
fi

success "Source analysis complete"

# Step 3: Project setup
bbpf "Step 3: Setting up refactor project..."
say "Setting up project: $PROJECT_NAME"

# Create project directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Initialize Claude Flow
npx claude-flow@alpha init --sparc --force $NONINTERACTIVE $VERBOSE_FLAG

success "Project environment setup complete"

# Step 4: Generate refactor prompt
bbam "Step 4: Generating Dr. House refactor prompt..."
say "Generating brutal refactor prompt..."

# Load source analysis
if [[ -f "../.source_analysis" ]]; then
  source ../.source_analysis
fi

REFACTOR_PROMPT="You are Dr. House, a brilliant but brutally honest medical diagnostician turned code refactorer. 

Your mission: Refactor the existing codebase into something better, but I will assess your work with brutal honesty.

SOURCE ANALYSIS:
$(cat ../.source_analysis 2>/dev/null || echo "No source analysis available")

TARGET FUNCTIONALITY: $TARGET_FUNCTIONALITY

DR. HOUSE REFACTORING CRITERIA:
1. IMPROVEMENT: Is the refactored code actually better than the original?
2. ARCHITECTURE: Is the new architecture sound and scalable?
3. FUNCTIONALITY: Does it implement the target functionality?
4. QUALITY: Is the code production-ready with proper practices?

RULES:
- Don't just move code around - actually improve it
- Use modern best practices and patterns
- Include proper error handling, logging, and documentation
- Make it production-ready, not just a demo
- If you can't improve it, don't refactor it
- I will assess your work brutally - prepare for criticism

Remember: I'm Dr. House. I don't care about your feelings. I care about quality.
If this refactoring is garbage, I'll tell you it's garbage. If it's good, I'll be surprised.

Now refactor something that's actually better than the original."

# Step 5: Run refactoring
bbpf "Step 5: Running Claude Flow refactoring..."
say "Running refactoring with Dr. House assessment..."

npx claude-flow@alpha task orchestrate --task "$REFACTOR_PROMPT" --strategy parallel $NONINTERACTIVE $VERBOSE_FLAG

success "Refactoring complete"

# Step 6: Dr. House assessment
if [[ "$BRUTAL_ASSESSMENT" == true ]]; then
  bbpf "Step 6: Running Dr. House brutal assessment..."
  say "Running refactor quality assessment..."
  
  # Assess refactor quality
  quality_result=0
  assess_refactor_quality "$(pwd)" "$(cat ../.source_analysis 2>/dev/null)" "$TARGET_FUNCTIONALITY" || quality_result=$?
  
  # Calculate score
  quality_score=80
  [[ $quality_result -eq 1 ]] && quality_score=60
  [[ $quality_result -eq 2 ]] && quality_score=30
  
  # Check against threshold
  threshold_score=$(echo "$QUALITY_THRESHOLD * 100" | bc -l | cut -d. -f1)
  
  if [[ $quality_score -ge $threshold_score ]]; then
    success "🎉 REFACTOR PASSES QUALITY THRESHOLD!"
    success "Quality score: $quality_score/100 (threshold: $threshold_score)"
  else
    house_roast "💥 REFACTOR FAILS QUALITY THRESHOLD!"
    house_roast "Quality score: $quality_score/100 (threshold: $threshold_score)"
    house_roast "This refactoring is garbage. Start over or keep the original."
    exit 1
  fi
fi

# Step 7: Generate refactor documentation
bbpf "Step 7: Generating refactor documentation..."
say "Generating refactor walkthrough..."

npx claude-flow@alpha task orchestrate --task "Read the repo and generate Refactor_Walkthrough.md covering: original source analysis, refactoring decisions, architecture changes, migration guide, testing strategy, and deployment differences. Focus on what was improved and why." --strategy sequential $NONINTERACTIVE $VERBOSE_FLAG

success "Refactor documentation generated"

# Step 8: Generate assessment report
if [[ "$BRUTAL_ASSESSMENT" == true ]]; then
  bbpf "Step 8: Generating Dr. House assessment report..."
  say "Generating assessment report..."
  
  cat > "DR_HOUSE_REFACTOR_ASSESSMENT.md" << EOF
# 🏥 Dr. House Refactor Assessment Report

**Project**: $PROJECT_NAME  
**Date**: $(date)  
**Assessor**: Dr. Gregory House, MD  

## 📊 Refactor Summary

### Source Analysis
$(cat ../.source_analysis 2>/dev/null || echo "No source analysis available")

### Target Functionality
$TARGET_FUNCTIONALITY

### Quality Score
- **Refactor Quality**: $quality_score/100
- **Threshold**: $threshold_score/100
- **Status**: $(if [[ $quality_score -ge $threshold_score ]]; then echo "PASSED"; else echo "FAILED"; fi)

### Verdict
$(if [[ $quality_result -eq 0 ]]; then
  echo "✅ **APPROVED** - Actually improved the code."
elif [[ $quality_result -eq 1 ]]; then
  echo "⚠️ **CONDITIONAL APPROVAL** - Some improvements, but could be better."
else
  echo "❌ **REJECTED** - Made it worse. Keep the original."
fi)

## 🎯 Recommendations

$(if [[ $quality_score -ge 80 ]]; then
  echo "1. Deploy the refactored version"
  echo "2. Monitor performance improvements"
  echo "3. Consider further optimizations"
elif [[ $quality_score -ge 60 ]]; then
  echo "1. Fix identified issues"
  echo "2. Add missing improvements"
  echo "3. Re-assess before deployment"
else
  echo "1. Revert to original code"
  echo "2. Get better requirements"
  echo "3. Hire competent developers"
  echo "4. Don't deploy this garbage"
fi)

---
*"Everybody lies, but code doesn't." - Dr. House*
EOF

  success "📋 Dr. House refactor assessment report generated: DR_HOUSE_REFACTOR_ASSESSMENT.md"
fi

# Final output
echo ""
echo -e "${CYAN}🏥 Code Refactor with Dr. House Assessment Complete${NC}"
echo -e "${PURPLE}===============================================${NC}"
echo ""
echo -e "${WHITE}Project:${NC} $PROJECT_NAME"
echo -e "${WHITE}Refactor Quality Score:${NC} $quality_score/100"
if [[ "$BRUTAL_ASSESSMENT" == true ]]; then
  echo -e "${WHITE}Assessment Report:${NC} DR_HOUSE_REFACTOR_ASSESSMENT.md"
fi
echo -e "${WHITE}Refactor Walkthrough:${NC} Refactor_Walkthrough.md"
echo ""
echo -e "${WHITE}Next Steps:${NC}"
if [[ $quality_score -ge 80 ]]; then
  echo "  🚀 Deploy refactored version"
  echo "  📊 Monitor improvements"
  echo "  🔧 Further optimizations"
else
  echo "  🔧 Fix refactoring issues"
  echo "  📝 Improve documentation"
  echo "  🔄 Re-assess before deployment"
fi
echo ""
echo -e "${GREEN}🏥 Dr. House has spoken. Listen to him.${NC}"
