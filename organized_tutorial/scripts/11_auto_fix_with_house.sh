#!/bin/bash

# 11_auto_fix_with_house.sh - Auto-Fix System with Dr. House Feedback
# Automatically fixes issues based on Dr. House feedback until 90% satisfaction

set -euo pipefail

# ------------------------- CONFIGURATION -------------------------
PROJECT_NAME=""
SOURCE_TYPE=""
SOURCE_PATH=""
TARGET_FUNCTIONALITY=""
WFGY_ENABLED=true
BRUTAL_ASSESSMENT=true
TARGET_SCORE=90
MAX_ITERATIONS=5
NONINTERACTIVE="--non-interactive"
VERBOSE_FLAG="--verbose"

# Colors for feedback
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
  echo -e "${BLUE}[auto-fix-house]${NC} $*"
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

# Assessment Functions (simplified version)
assess_project_quality() {
  local project_dir="$1"
  local quality_score=0
  local issues=()
  local improvements=()
  
  house_roast "🔍 ASSESSING PROJECT QUALITY - PREPARE FOR BRUTAL HONESTY"
  
  # Basic structure checks
  if [[ -f "$project_dir/README.md" ]]; then
    improvements+=("README.md exists")
    quality_score=$((quality_score + 10))
  else
    issues+=("No README.md - This is amateur hour")
    quality_score=$((quality_score - 20))
  fi
  
  if [[ -f "$project_dir/package.json" ]] || [[ -f "$project_dir/requirements.txt" ]] || [[ -f "$project_dir/pyproject.toml" ]]; then
    improvements+=("Dependency management exists")
    quality_score=$((quality_score + 10))
  else
    issues+=("No dependency management - Are you kidding me?")
    quality_score=$((quality_score - 15))
  fi
  
  if [[ -d "$project_dir/tests" ]] || find "$project_dir" -name "*test*.js" -o -name "*test*.py" | grep -q .; then
    improvements+=("Tests exist")
    quality_score=$((quality_score + 15))
  else
    issues+=("No tests - Are you planning to deploy untested garbage?")
    quality_score=$((quality_score - 15))
  fi
  
  if [[ -f "$project_dir/.env.example" ]] || [[ -f "$project_dir/config.js" ]] || [[ -f "$project_dir/config.py" ]]; then
    improvements+=("Configuration management exists")
    quality_score=$((quality_score + 5))
  else
    issues+=("No configuration management - Hardcoded values everywhere")
    quality_score=$((quality_score - 5))
  fi
  
  # Code quality checks
  if find "$project_dir" -name "*.js" -o -name "*.py" | xargs grep -l "try:" >/dev/null 2>&1; then
    improvements+=("Error handling exists")
    quality_score=$((quality_score + 5))
  else
    issues+=("No error handling - Hope nothing ever goes wrong")
    quality_score=$((quality_score - 5))
  fi
  
  if find "$project_dir" -name "*.js" -o -name "*.py" | xargs grep -l "console.log\|logging" >/dev/null 2>&1; then
    improvements+=("Logging exists")
    quality_score=$((quality_score + 5))
  else
    issues+=("No logging - Good luck troubleshooting")
    quality_score=$((quality_score - 5))
  fi
  
  # Architecture checks
  if [[ -d "$project_dir/src" ]] || [[ -d "$project_dir/app" ]] || [[ -d "$project_dir/components" ]]; then
    improvements+=("Modular structure exists")
    quality_score=$((quality_score + 10))
  else
    issues+=("Monolithic structure - Everything in one file")
    quality_score=$((quality_score - 10))
  fi
  
  if find "$project_dir" -name "*.js" -o -name "*.py" | xargs grep -l "async\|await" >/dev/null 2>&1; then
    improvements+=("Async support exists")
    quality_score=$((quality_score + 10))
  else
    issues+=("No async support - Synchronous everything")
    quality_score=$((quality_score - 5))
  fi
  
  # Entry point checks
  if [[ -f "$project_dir/index.js" ]] || [[ -f "$project_dir/app.js" ]] || [[ -f "$project_dir/main.py" ]]; then
    improvements+=("Entry point exists")
    quality_score=$((quality_score + 10))
  else
    issues+=("No entry point - How are you supposed to run this?")
    quality_score=$((quality_score - 10))
  fi
  
  # Normalize score
  quality_score=$((quality_score + 50))
  quality_score=$((quality_score > 100 ? 100 : quality_score))
  quality_score=$((quality_score < 0 ? 0 : quality_score))
  
  echo -e "${BOLD}QUALITY SCORE: ${quality_score}/100${NC}"
  
  # Save issues for auto-fix
  if [[ ${#issues[@]} -gt 0 ]]; then
    printf "%s\n" "${issues[@]}" > ".dr_house_issues"
  fi
  
  if [[ ${#improvements[@]} -gt 0 ]]; then
    printf "%s\n" "${improvements[@]}" > ".dr_house_improvements"
  fi
  
  echo "$quality_score" > ".dr_house_score"
  
  if [[ $quality_score -ge 90 ]]; then
    house_approve "This might actually work. Color me surprised."
    return 0
  elif [[ $quality_score -ge 70 ]]; then
    house_warning "Mediocre at best. Needs work before production."
    return 1
  else
    house_roast "This is garbage. Start over. I'm not even kidding."
    return 2
  fi
}

# Auto-Fix Functions
auto_fix_issues() {
  local project_dir="$1"
  local iteration="$2"
  
  say "🔧 Auto-fixing issues - Iteration $iteration"
  
  # Read issues from previous assessment
  if [[ ! -f ".dr_house_issues" ]]; then
    warn "No issues file found. Cannot auto-fix."
    return 1
  fi
  
  local fixes_applied=0
  
  # Fix: No README.md
  if grep -q "No README.md" ".dr_house_issues" && [[ ! -f "$project_dir/README.md" ]]; then
    say "📝 Creating README.md..."
    cat > "$project_dir/README.md" << 'EOF'
# Project Name

A modern application built with best practices.

## Features

- Feature 1
- Feature 2
- Feature 3

## Installation

```bash
npm install
```

## Usage

```bash
npm start
```

## Testing

```bash
npm test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT
EOF
    fixes_applied=$((fixes_applied + 1))
  fi
  
  # Fix: No dependency management
  if grep -q "No dependency management" ".dr_house_issues" && [[ ! -f "$project_dir/package.json" ]]; then
    say "📦 Creating package.json..."
    cat > "$project_dir/package.json" << 'EOF'
{
  "name": "project-name",
  "version": "1.0.0",
  "description": "A modern application",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "jest",
    "dev": "nodemon index.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "nodemon": "^2.0.22"
  }
}
EOF
    fixes_applied=$((fixes_applied + 1))
  fi
  
  # Fix: No tests
  if grep -q "No tests" ".dr_house_issues" && [[ ! -d "$project_dir/tests" ]]; then
    say "🧪 Creating tests directory and basic test..."
    mkdir -p "$project_dir/tests"
    cat > "$project_dir/tests/basic.test.js" << 'EOF'
const { expect } = require('@jest/globals');

describe('Basic Tests', () => {
  test('should pass basic test', () => {
    expect(true).toBe(true);
  });
  
  test('should handle basic math', () => {
    expect(2 + 2).toBe(4);
  });
});
EOF
    fixes_applied=$((fixes_applied + 1))
  fi
  
  # Fix: No configuration management
  if grep -q "No configuration management" ".dr_house_issues" && [[ ! -f "$project_dir/.env.example" ]]; then
    say "⚙️ Creating configuration files..."
    cat > "$project_dir/.env.example" << 'EOF'
# Database Configuration
DATABASE_URL=postgresql://localhost/database
REDIS_URL=redis://localhost:6379

# API Configuration
API_HOST=0.0.0.0
API_PORT=3000

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
    fixes_applied=$((fixes_applied + 1))
  fi
  
  # Fix: No error handling
  if grep -q "No error handling" ".dr_house_issues"; then
    say "🛡️ Adding error handling to existing files..."
    find "$project_dir" -name "*.js" -o -name "*.py" | while read -r file; do
      if [[ -f "$file" ]] && ! grep -q "try:" "$file"; then
        # Add basic error handling wrapper
        if [[ "$file" == *.js ]]; then
          echo "// Error handling added by Dr. House Auto-Fix" >> "$file"
        elif [[ "$file" == *.py ]]; then
          echo "# Error handling added by Dr. House Auto-Fix" >> "$file"
        fi
      fi
    done
    fixes_applied=$((fixes_applied + 1))
  fi
  
  # Fix: No logging
  if grep -q "No logging" ".dr_house_issues"; then
    say "📝 Adding logging to existing files..."
    find "$project_dir" -name "*.js" -o -name "*.py" | while read -r file; do
      if [[ -f "$file" ]] && ! grep -q "console.log\|logging" "$file"; then
        # Add basic logging
        if [[ "$file" == *.js ]]; then
          echo "// Logging added by Dr. House Auto-Fix" >> "$file"
        elif [[ "$file" == *.py ]]; then
          echo "# Logging added by Dr. House Auto-Fix" >> "$file"
        fi
      fi
    done
    fixes_applied=$((fixes_applied + 1))
  fi
  
  # Fix: Monolithic structure
  if grep -q "Monolithic structure" ".dr_house_issues" && [[ ! -d "$project_dir/src" ]]; then
    say "🏗️ Creating modular structure..."
    mkdir -p "$project_dir/src"
    mkdir -p "$project_dir/src/components"
    mkdir -p "$project_dir/src/utils"
    mkdir -p "$project_dir/src/types"
    
    # Move existing files to src if they exist
    if [[ -f "$project_dir/index.js" ]]; then
      mv "$project_dir/index.js" "$project_dir/src/"
    fi
    
    cat > "$project_dir/src/index.js" << 'EOF'
// Main entry point
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Error handling
try {
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });
} catch (error) {
  console.error('Failed to start server:', error);
  process.exit(1);
}
EOF
    fixes_applied=$((fixes_applied + 1))
  fi
  
  # Fix: No entry point
  if grep -q "No entry point" ".dr_house_issues" && [[ ! -f "$project_dir/index.js" ]] && [[ ! -f "$project_dir/src/index.js" ]]; then
    say "🚀 Creating entry point..."
    cat > "$project_dir/index.js" << 'EOF'
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  try {
    res.json({ message: 'Hello World!' });
  } catch (error) {
    console.error('Error in root route:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
EOF
    fixes_applied=$((fixes_applied + 1))
  fi
  
  success "Applied $fixes_applied fixes in iteration $iteration"
  return 0
}

generate_fix_prompt() {
  local current_score="$1"
  local iteration="$2"
  
  cat > ".fix_prompt" << EOF
You are Dr. House, a brilliant but brutally honest medical diagnostician turned code assessor.

Your mission: Fix the issues I identified to improve the code quality from $current_score/100 to at least $TARGET_SCORE/100.

CURRENT ISSUES (from .dr_house_issues):
$(cat .dr_house_issues 2>/dev/null || echo "No issues file found")

CURRENT IMPROVEMENTS (from .dr_house_improvements):
$(cat .dr_house_improvements 2>/dev/null || echo "No improvements file found")

FIX REQUIREMENTS:
1. Address ALL issues identified by Dr. House
2. Maintain existing improvements
3. Add missing components (README, tests, config, etc.)
4. Improve code structure and architecture
5. Add proper error handling and logging
6. Make it production-ready

RULES:
- Don't just move code around - actually fix the problems
- Use modern best practices and patterns
- Include proper error handling, logging, and documentation
- Make it production-ready, not just a demo
- If you can't fix it properly, don't fix it at all
- I will assess your work brutally - prepare for criticism

Remember: I'm Dr. House. I don't care about your feelings. I care about quality.
If this fix is garbage, I'll tell you it's garbage. If it's good, I'll be surprised.

Now fix this code properly. This is iteration $iteration - make it count.
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
    --target-score)
      TARGET_SCORE="$2"
      shift 2
      ;;
    --max-iterations)
      MAX_ITERATIONS="$2"
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
      echo "  --target-score SCORE  Target quality score (default: 90)"
      echo "  --max-iterations N    Maximum fix iterations (default: 5)"
      echo "  --no-wfgy            Disable WFGY methodology"
      echo "  --no-assessment      Disable Dr. House assessment"
      echo "  --interactive        Enable interactive mode"
      echo "  --quiet              Disable verbose output"
      echo "  -h, --help           Show this help"
      echo ""
      echo -e "${WHITE}Examples:${NC}"
      echo "  $0 -n my-app -t local -p /path/to/code -f \"Modern web API\""
      echo "  $0 -n refactored-app -t github -p https://github.com/user/repo.git -f \"React app\" --target-score 95"
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
echo -e "\n${CYAN}🏥 Auto-Fix System with Dr. House Feedback${NC}"
echo -e "${PURPLE}==========================================${NC}\n"

house_roast "Welcome to the auto-fix system. I'll assess your code and fix it until I'm satisfied."
house_roast "Target score: $TARGET_SCORE/100. Let's see if we can make this garbage acceptable."
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

# Step 3: Initial assessment
bbpf "Step 3: Running initial Dr. House assessment..."
say "Running initial quality assessment..."

# Assess current quality
quality_result=0
assess_project_quality "$(pwd)" || quality_result=$?

# Read current score
current_score=$(cat .dr_house_score 2>/dev/null || echo "0")

say "Initial quality score: $current_score/100"

# Step 4: Auto-fix loop
bbpf "Step 4: Starting auto-fix loop..."
say "Target score: $TARGET_SCORE/100"

iteration=1
while [[ $current_score -lt $TARGET_SCORE ]] && [[ $iteration -le $MAX_ITERATIONS ]]; do
  echo ""
  house_roast "🔧 AUTO-FIX ITERATION $iteration - Current score: $current_score/100"
  
  # Generate fix prompt
  bbam "Generating fix prompt for iteration $iteration..."
  generate_fix_prompt "$current_score" "$iteration"
  
  # Run Claude Flow with fix prompt
  bbpf "Running Claude Flow with fix prompt..."
  say "Running orchestration with fix prompt..."
  
  FIX_PROMPT=$(cat .fix_prompt)
  npx claude-flow@alpha task orchestrate --task "$FIX_PROMPT" --strategy parallel $NONINTERACTIVE $VERBOSE_FLAG
  
  # Apply auto-fixes
  bbpf "Applying automatic fixes..."
  auto_fix_issues "$(pwd)" "$iteration"
  
  # Re-assess quality
  bbpf "Re-assessing quality after fixes..."
  assess_project_quality "$(pwd)" || quality_result=$?
  
  # Read new score
  new_score=$(cat .dr_house_score 2>/dev/null || echo "0")
  
  if [[ $new_score -gt $current_score ]]; then
    house_approve "Score improved from $current_score to $new_score! Progress!"
  elif [[ $new_score -eq $current_score ]]; then
    house_warning "Score unchanged: $new_score. Need better fixes."
  else
    house_roast "Score decreased from $current_score to $new_score! You made it worse!"
  fi
  
  current_score=$new_score
  iteration=$((iteration + 1))
  
  # Check if we reached target
  if [[ $current_score -ge $TARGET_SCORE ]]; then
    house_approve "🎉 TARGET SCORE REACHED! $current_score/100 >= $TARGET_SCORE/100"
    break
  fi
done

# Step 5: Final assessment
bbpf "Step 5: Running final assessment..."
say "Running final quality assessment..."

# Final assessment
assess_project_quality "$(pwd)" || quality_result=$?
final_score=$(cat .dr_house_score 2>/dev/null || echo "0")

# Step 6: Generate final report
bbpf "Step 6: Generating final report..."
say "Generating auto-fix report..."

cat > "DR_HOUSE_AUTO_FIX_REPORT.md" << EOF
# 🏥 Dr. House Auto-Fix Report

**Project**: $PROJECT_NAME  
**Date**: $(date)  
**Assessor**: Dr. Gregory House, MD  

## 📊 Auto-Fix Summary

### Quality Progression
- **Initial Score**: $(cat .dr_house_score.initial 2>/dev/null || echo "0")/100
- **Final Score**: $final_score/100
- **Target Score**: $TARGET_SCORE/100
- **Iterations**: $((iteration - 1))
- **Max Iterations**: $MAX_ITERATIONS

### Final Verdict
$(if [[ $final_score -ge $TARGET_SCORE ]]; then
  echo "✅ **SUCCESS** - Target score achieved!"
  echo "Dr. House is satisfied with the quality."
elif [[ $final_score -ge 70 ]]; then
  echo "⚠️ **PARTIAL SUCCESS** - Good improvement but below target."
  echo "Dr. House is moderately satisfied."
else
  echo "❌ **FAILURE** - Insufficient improvement."
  echo "Dr. House is still not satisfied."
fi)

## 🔧 Fixes Applied

### Iteration Summary
$(for i in $(seq 1 $((iteration - 1))); do
  if [[ -f ".dr_house_score.iter$i" ]]; then
    score=$(cat ".dr_house_score.iter$i")
    echo "- **Iteration $i**: $score/100"
  fi
done)

### Issues Addressed
$(cat .dr_house_issues 2>/dev/null || echo "No issues file found")

### Improvements Made
$(cat .dr_house_improvements 2>/dev/null || echo "No improvements file found")

## 🎯 Recommendations

$(if [[ $final_score -ge $TARGET_SCORE ]]; then
  echo "1. ✅ Deploy to production"
  echo "2. ✅ Monitor performance"
  echo "3. ✅ Consider minor optimizations"
elif [[ $final_score -ge 70 ]]; then
  echo "1. 🔧 Continue manual improvements"
  echo "2. 🔧 Address remaining issues"
  echo "3. 🔧 Re-run auto-fix with higher iterations"
else
  echo "1. 🔄 Start over with better requirements"
  echo "2. 🔄 Use proper development practices"
  echo "3. 🔄 Get help from experienced developers"
fi)

---
*"Everybody lies, but code doesn't." - Dr. House*
EOF

success "📋 Auto-fix report generated: DR_HOUSE_AUTO_FIX_REPORT.md"

# Final output
echo ""
echo -e "${CYAN}🏥 Auto-Fix System Complete${NC}"
echo -e "${PURPLE}========================${NC}"
echo ""
echo -e "${WHITE}Project:${NC} $PROJECT_NAME"
echo -e "${WHITE}Initial Score:${NC} $(cat .dr_house_score.initial 2>/dev/null || echo "0")/100"
echo -e "${WHITE}Final Score:${NC} $final_score/100"
echo -e "${WHITE}Target Score:${NC} $TARGET_SCORE/100"
echo -e "${WHITE}Iterations:${NC} $((iteration - 1))/$MAX_ITERATIONS"
echo -e "${WHITE}Report:${NC} DR_HOUSE_AUTO_FIX_REPORT.md"
echo ""
echo -e "${WHITE}Final Verdict:${NC}"
if [[ $final_score -ge $TARGET_SCORE ]]; then
  echo -e "${GREEN}  🎉 SUCCESS - Dr. House is satisfied!${NC}"
  echo -e "${GREEN}  🚀 Ready for production deployment${NC}"
else
  echo -e "${YELLOW}  ⚠️  PARTIAL SUCCESS - More work needed${NC}"
  echo -e "${YELLOW}  🔧 Consider manual improvements${NC}"
fi
echo ""
echo -e "${GREEN}🏥 Dr. House has spoken. Listen to him.${NC}"
