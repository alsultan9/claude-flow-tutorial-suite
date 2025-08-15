#!/bin/bash

# 08_brutal_assessor.sh - Dr. House Brutal Honest Assessor
# Ensures Claude Flow agents don't produce shit work

set -euo pipefail

# ------------------------- CONFIGURATION -------------------------
PROJECT_NAME=""
SPARC_MODE="auto"
TOPOLOGY="auto"
AGENTS=7
IDEA_TEXT=""
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
  echo -e "${BLUE}[brutal-assessor]${NC} $*"
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

# Dr. House Brutal Assessment Functions
house_roast() {
  echo -e "${RED}${BOLD}🏥 DR. HOUSE BRUTAL ASSESSMENT:${NC}"
  echo -e "${RED}================================${NC}"
  echo -e "${RED}$*${NC}"
  echo ""
}

house_approve() {
  echo -e "${GREEN}${BOLD}✅ DR. HOUSE APPROVAL:${NC}"
  echo -e "${GREEN}$*${NC}"
  echo ""
}

house_warning() {
  echo -e "${YELLOW}${BOLD}⚠️  DR. HOUSE WARNING:${NC}"
  echo -e "${YELLOW}$*${NC}"
  echo ""
}

# Quality Assessment Functions
assess_code_quality() {
  local project_dir="$1"
  local quality_score=0
  local issues=()
  local warnings=()
  
  house_roast "🔍 ASSESSING CODE QUALITY - PREPARE FOR BRUTAL HONESTY"
  
  # Check for basic project structure
  if [[ ! -f "$project_dir/README.md" ]]; then
    issues+=("No README.md - This is amateur hour")
    quality_score=$((quality_score - 20))
  fi
  
  if [[ ! -f "$project_dir/requirements.txt" ]] && [[ ! -f "$project_dir/pyproject.toml" ]]; then
    issues+=("No dependency management - Are you kidding me?")
    quality_score=$((quality_score - 15))
  fi
  
  # Check for proper Python structure
  if [[ -d "$project_dir/src" ]] || [[ -d "$project_dir" ]]; then
    # Look for __init__.py files
    if ! find "$project_dir" -name "__init__.py" | grep -q .; then
      warnings+=("No __init__.py files - Python packaging 101, people!")
    fi
    
    # Check for proper imports
    if find "$project_dir" -name "*.py" | head -5 | xargs grep -l "import" >/dev/null 2>&1; then
      house_approve "At least they know how to import modules"
      quality_score=$((quality_score + 5))
    fi
  fi
  
  # Check for tests
  if [[ -d "$project_dir/tests" ]] || find "$project_dir" -name "*test*.py" | grep -q .; then
    house_approve "Tests exist - Not completely incompetent"
    quality_score=$((quality_score + 10))
  else
    issues+=("No tests - Are you planning to deploy untested garbage?")
    quality_score=$((quality_score - 15))
  fi
  
  # Check for documentation
  if find "$project_dir" -name "*.md" | grep -q .; then
    house_approve "Documentation exists - Someone actually thought about users"
    quality_score=$((quality_score + 10))
  else
    warnings+=("Minimal documentation - Hope you like debugging")
  fi
  
  # Check for configuration
  if [[ -f "$project_dir/.env.example" ]] || [[ -f "$project_dir/config.py" ]]; then
    house_approve "Configuration management - Not completely clueless"
    quality_score=$((quality_score + 5))
  else
    warnings+=("No configuration management - Hardcoded values everywhere")
  fi
  
  # Check for proper error handling
  if find "$project_dir" -name "*.py" | xargs grep -l "try:" >/dev/null 2>&1; then
    house_approve "Error handling exists - Someone thought about edge cases"
    quality_score=$((quality_score + 5))
  else
    warnings+=("No error handling - Hope nothing ever goes wrong")
  fi
  
  # Check for logging
  if find "$project_dir" -name "*.py" | xargs grep -l "logging\|log" >/dev/null 2>&1; then
    house_approve "Logging implemented - At least we can debug this mess"
    quality_score=$((quality_score + 5))
  else
    warnings+=("No logging - Good luck troubleshooting in production")
  fi
  
  # Normalize score to 0-100
  quality_score=$((quality_score + 50))  # Start at 50
  quality_score=$((quality_score > 100 ? 100 : quality_score))
  quality_score=$((quality_score < 0 ? 0 : quality_score))
  
  # Report findings
  echo -e "${BOLD}QUALITY SCORE: ${quality_score}/100${NC}"
  echo ""
  
  if [[ ${#issues[@]} -gt 0 ]]; then
    house_roast "🚨 CRITICAL ISSUES FOUND:"
    for issue in "${issues[@]}"; do
      echo -e "${RED}  ❌ $issue${NC}"
    done
    echo ""
  fi
  
  if [[ ${#warnings[@]} -gt 0 ]]; then
    house_warning "⚠️  WARNINGS:"
    for warning in "${warnings[@]}"; do
      echo -e "${YELLOW}  ⚠️  $warning${NC}"
    done
    echo ""
  fi
  
  # Final assessment
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

assess_architecture() {
  local project_dir="$1"
  
  house_roast "🏗️  ASSESSING ARCHITECTURE - LET'S SEE WHAT MESS THEY MADE"
  
  local architecture_score=0
  local issues=()
  
  # Check for modular structure
  if [[ -d "$project_dir/src" ]] || [[ -d "$project_dir/lib" ]] || [[ -d "$project_dir/app" ]]; then
    house_approve "Modular structure detected - Someone read a book"
    architecture_score=$((architecture_score + 20))
  else
    issues+=("Monolithic structure - Everything in one file, classic amateur move")
    architecture_score=$((architecture_score - 20))
  fi
  
  # Check for separation of concerns
  if find "$project_dir" -type d | grep -E "(api|core|models|utils|services)" | head -3 | grep -q .; then
    house_approve "Separation of concerns - They actually thought about organization"
    architecture_score=$((architecture_score + 15))
  else
    issues+=("No separation of concerns - Everything mixed together like a bad smoothie")
  fi
  
  # Check for configuration management
  if [[ -f "$project_dir/config.py" ]] || [[ -f "$project_dir/settings.py" ]] || [[ -f "$project_dir/.env.example" ]]; then
    house_approve "Configuration management - Not hardcoding everything"
    architecture_score=$((architecture_score + 10))
  else
    issues+=("No configuration management - Hardcoded values everywhere")
  fi
  
  # Check for dependency injection or proper imports
  if find "$project_dir" -name "*.py" | xargs grep -l "from.*import" | head -3 | grep -q .; then
    house_approve "Proper imports - At least they know how modules work"
    architecture_score=$((architecture_score + 10))
  else
    issues+=("Poor import structure - Everything imported globally")
  fi
  
  # Check for async support (modern requirement)
  if find "$project_dir" -name "*.py" | xargs grep -l "async\|await" | grep -q .; then
    house_approve "Async support - They're not stuck in 2010"
    architecture_score=$((architecture_score + 15))
  else
    warnings+=("No async support - Synchronous everything, how quaint")
  fi
  
  # Check for API structure
  if find "$project_dir" -name "*.py" | xargs grep -l "FastAPI\|flask\|django" | grep -q .; then
    house_approve "Web framework detected - They know how to build APIs"
    architecture_score=$((architecture_score + 10))
  fi
  
  # Check for database models
  if find "$project_dir" -name "*.py" | xargs grep -l "class.*Model\|@dataclass\|BaseModel" | grep -q .; then
    house_approve "Data models defined - Structure exists"
    architecture_score=$((architecture_score + 10))
  else
    issues+=("No data models - Just raw dictionaries everywhere")
  fi
  
  # Normalize score
  architecture_score=$((architecture_score + 50))
  architecture_score=$((architecture_score > 100 ? 100 : architecture_score))
  architecture_score=$((architecture_score < 0 ? 0 : architecture_score))
  
  echo -e "${BOLD}ARCHITECTURE SCORE: ${architecture_score}/100${NC}"
  echo ""
  
  if [[ ${#issues[@]} -gt 0 ]]; then
    house_roast "🏗️  ARCHITECTURE ISSUES:"
    for issue in "${issues[@]}"; do
      echo -e "${RED}  ❌ $issue${NC}"
    done
    echo ""
  fi
  
  if [[ $architecture_score -ge 80 ]]; then
    house_approve "Solid architecture. I might actually use this."
    return 0
  elif [[ $architecture_score -ge 60 ]]; then
    house_warning "Decent architecture. Needs refinement."
    return 1
  else
    house_roast "Architectural disaster. Tear it down and start over."
    return 2
  fi
}

assess_functionality() {
  local project_dir="$1"
  local idea_text="$2"
  
  house_roast "🎯 ASSESSING FUNCTIONALITY - DOES IT ACTUALLY DO WHAT YOU ASKED?"
  
  local functionality_score=0
  local issues=()
  
  # Check if the project actually implements what was requested
  if [[ -n "$idea_text" ]]; then
    # Look for key terms in the idea
    local idea_lower=$(echo "$idea_text" | tr '[:upper:]' '[:lower:]')
    
    # Check for API implementation
    if echo "$idea_lower" | grep -q "api\|rest\|web" && find "$project_dir" -name "*.py" | xargs grep -l "FastAPI\|flask\|django\|app.route" | grep -q .; then
      house_approve "API implementation found - They actually built what you asked for"
      functionality_score=$((functionality_score + 25))
    elif echo "$idea_lower" | grep -q "api\|rest\|web"; then
      issues+=("Requested API but no web framework found - Did they even read the requirements?")
      functionality_score=$((functionality_score - 20))
    fi
    
    # Check for database implementation
    if echo "$idea_lower" | grep -q "database\|db\|data" && find "$project_dir" -name "*.py" | xargs grep -l "sqlalchemy\|django.db\|postgres\|mysql" | grep -q .; then
      house_approve "Database implementation found - Data persistence exists"
      functionality_score=$((functionality_score + 20))
    elif echo "$idea_lower" | grep -q "database\|db\|data"; then
      issues+=("Requested database but no ORM/database code found")
      functionality_score=$((functionality_score - 15))
    fi
    
    # Check for CLI implementation
    if echo "$idea_lower" | grep -q "cli\|command\|terminal" && find "$project_dir" -name "*.py" | xargs grep -l "click\|argparse\|typer" | grep -q .; then
      house_approve "CLI implementation found - Command line interface exists"
      functionality_score=$((functionality_score + 15))
    elif echo "$idea_lower" | grep -q "cli\|command\|terminal"; then
      issues+=("Requested CLI but no command line interface found")
      functionality_score=$((functionality_score - 10))
    fi
    
    # Check for authentication
    if echo "$idea_lower" | grep -q "auth\|login\|user" && find "$project_dir" -name "*.py" | xargs grep -l "jwt\|oauth\|password\|login" | grep -q .; then
      house_approve "Authentication implementation found - Security considered"
      functionality_score=$((functionality_score + 15))
    elif echo "$idea_lower" | grep -q "auth\|login\|user"; then
      issues+=("Requested authentication but no auth code found - Security nightmare")
      functionality_score=$((functionality_score - 15))
    fi
  fi
  
  # Check for basic functionality files
  if [[ -f "$project_dir/main.py" ]] || [[ -f "$project_dir/app.py" ]] || [[ -f "$project_dir/run.py" ]]; then
    house_approve "Entry point exists - You can actually run this thing"
    functionality_score=$((functionality_score + 10))
  else
    issues+=("No entry point - How are you supposed to run this?")
    functionality_score=$((functionality_score - 10))
  fi
  
  # Check for setup/installation
  if [[ -f "$project_dir/setup.py" ]] || [[ -f "$project_dir/pyproject.toml" ]] || [[ -f "$project_dir/requirements.txt" ]]; then
    house_approve "Installation files exist - Someone thought about deployment"
    functionality_score=$((functionality_score + 10))
  else
    issues+=("No installation files - Good luck deploying this mess")
    functionality_score=$((functionality_score - 10))
  fi
  
  # Normalize score
  functionality_score=$((functionality_score + 50))
  functionality_score=$((functionality_score > 100 ? 100 : functionality_score))
  functionality_score=$((functionality_score < 0 ? 0 : functionality_score))
  
  echo -e "${BOLD}FUNCTIONALITY SCORE: ${functionality_score}/100${NC}"
  echo ""
  
  if [[ ${#issues[@]} -gt 0 ]]; then
    house_roast "🎯 FUNCTIONALITY ISSUES:"
    for issue in "${issues[@]}"; do
      echo -e "${RED}  ❌ $issue${NC}"
    done
    echo ""
  fi
  
  if [[ $functionality_score -ge 80 ]]; then
    house_approve "Actually does what you asked. Miracles do happen."
    return 0
  elif [[ $functionality_score -ge 60 ]]; then
    house_warning "Partially functional. Better than nothing, I guess."
    return 1
  else
    house_roast "Doesn't do what you asked. Complete waste of time."
    return 2
  fi
}

brutal_final_assessment() {
  local code_score="$1"
  local arch_score="$2"
  local func_score="$3"
  local project_dir="$4"
  
  house_roast "🏥 FINAL BRUTAL ASSESSMENT - THE MOMENT OF TRUTH"
  echo -e "${BOLD}===============================================${NC}"
  echo ""
  
  # Calculate overall score
  local overall_score=$(( (code_score + arch_score + func_score) / 3 ))
  
  echo -e "${BOLD}OVERALL QUALITY SCORE: ${overall_score}/100${NC}"
  echo ""
  
  # Dr. House's final verdict
  if [[ $overall_score -ge 85 ]]; then
    house_approve "🏆 EXCELLENT WORK - This is actually good. I'm impressed."
    house_approve "You can deploy this to production. It won't embarrass you."
    return 0
  elif [[ $overall_score -ge 70 ]]; then
    house_warning "📊 DECENT WORK - Not terrible, but needs improvement."
    house_warning "Fix the issues before production deployment."
    return 1
  elif [[ $overall_score -ge 50 ]]; then
    house_roast "😐 MEDIOCRE - Better than nothing, but barely."
    house_roast "Significant work needed before this is usable."
    return 2
  else
    house_roast "💩 COMPLETE GARBAGE - This is embarrassing."
    house_roast "Start over. Don't waste my time with this amateur hour."
    return 3
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
      echo "  --no-assessment      Disable brutal assessment"
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
echo -e "\n${CYAN}🏥 Dr. House Brutal Honest Assessor${NC}"
echo -e "${PURPLE}================================${NC}\n"

house_roast "Welcome to the brutal assessment. I don't sugarcoat anything."
house_roast "If your agents produce garbage, I'll tell you. If they do good work, I'll be surprised."
echo ""

# Step 1: Run Claude Flow orchestration
say "Step 1: Running Claude Flow orchestration with brutal assessment..."

# Create project directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Initialize Claude Flow
npx claude-flow@alpha init --sparc --force $NONINTERACTIVE $VERBOSE_FLAG

# Generate brutal assessment prompt
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

# Run orchestration with brutal assessment
npx claude-flow@alpha task orchestrate --task "$BRUTAL_PROMPT" --strategy parallel $NONINTERACTIVE $VERBOSE_FLAG

# Step 2: Brutal Assessment
if [[ "$BRUTAL_ASSESSMENT" == true ]]; then
  say "Step 2: Running Dr. House brutal assessment..."
  
  # Assess code quality
  code_quality_result=0
  assess_code_quality "$(pwd)" || code_quality_result=$?
  
  # Assess architecture
  arch_result=0
  assess_architecture "$(pwd)" || arch_result=$?
  
  # Assess functionality
  func_result=0
  assess_functionality "$(pwd)" "$IDEA_TEXT" || func_result=$?
  
  # Calculate scores (convert exit codes to scores)
  code_score=80
  [[ $code_quality_result -eq 1 ]] && code_score=60
  [[ $code_quality_result -eq 2 ]] && code_score=30
  
  arch_score=80
  [[ $arch_result -eq 1 ]] && arch_score=60
  [[ $arch_result -eq 2 ]] && arch_score=30
  
  func_score=80
  [[ $func_result -eq 1 ]] && func_score=60
  [[ $func_result -eq 2 ]] && func_score=30
  
  # Final brutal assessment
  final_result=0
  brutal_final_assessment "$code_score" "$arch_score" "$func_score" "$(pwd)" || final_result=$?
  
  # Determine if project passes quality threshold
  overall_score=$(( (code_score + arch_score + func_score) / 3 ))
  threshold_score=$((QUALITY_THRESHOLD * 100))
  
  if [[ $overall_score -ge $threshold_score ]]; then
    success "🎉 PROJECT PASSES QUALITY THRESHOLD!"
    success "Overall score: $overall_score/100 (threshold: $threshold_score)"
  else
    house_roast "💥 PROJECT FAILS QUALITY THRESHOLD!"
    house_roast "Overall score: $overall_score/100 (threshold: $threshold_score)"
    house_roast "Fix the issues or start over. I'm not deploying garbage."
    exit 1
  fi
fi

# Step 3: Generate assessment report
say "Step 3: Generating Dr. House assessment report..."

cat > "DR_HOUSE_ASSESSMENT.md" << EOF
# 🏥 Dr. House Brutal Assessment Report

**Project**: $PROJECT_NAME  
**Date**: $(date)  
**Assessor**: Dr. Gregory House, MD  

## 📊 Assessment Summary

### Quality Scores
- **Code Quality**: $code_score/100
- **Architecture**: $arch_score/100  
- **Functionality**: $func_score/100
- **Overall Score**: $overall_score/100

### Verdict
$(if [[ $final_result -eq 0 ]]; then
  echo "✅ **APPROVED** - This is actually good work."
elif [[ $final_result -eq 1 ]]; then
  echo "⚠️ **CONDITIONAL APPROVAL** - Needs improvement before production."
elif [[ $final_result -eq 2 ]]; then
  echo "❌ **REJECTED** - Significant work needed."
else
  echo "💩 **COMPLETE REJECTION** - Start over. This is garbage."
fi)

## 🔍 Detailed Findings

### Code Quality Issues
$(if [[ $code_quality_result -eq 0 ]]; then
  echo "- Code quality is acceptable"
elif [[ $code_quality_result -eq 1 ]]; then
  echo "- Some code quality issues found"
else
  echo "- Major code quality problems"
fi)

### Architecture Issues  
$(if [[ $arch_result -eq 0 ]]; then
  echo "- Architecture is sound"
elif [[ $arch_result -eq 1 ]]; then
  echo "- Some architectural concerns"
else
  echo "- Major architectural problems"
fi)

### Functionality Issues
$(if [[ $func_result -eq 0 ]]; then
  echo "- Functionality meets requirements"
elif [[ $func_result -eq 1 ]]; then
  echo "- Some functionality gaps"
else
  echo "- Major functionality problems"
fi)

## 🎯 Recommendations

$(if [[ $overall_score -ge 85 ]]; then
  echo "1. Deploy to production"
  echo "2. Monitor performance"
  echo "3. Consider minor optimizations"
elif [[ $overall_score -ge 70 ]]; then
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

# Final output
echo ""
echo -e "${CYAN}🏥 Dr. House Brutal Assessment Complete${NC}"
echo -e "${PURPLE}=====================================${NC}"
echo ""
echo -e "${WHITE}Project:${NC} $PROJECT_DIR"
echo -e "${WHITE}Overall Score:${NC} $overall_score/100"
echo -e "${WHITE}Assessment Report:${NC} DR_HOUSE_ASSESSMENT.md"
echo ""
echo -e "${WHITE}Next Steps:${NC}"
if [[ $overall_score -ge 85 ]]; then
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
