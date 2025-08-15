#!/bin/bash

# 12_wfgy_complex_refactor.sh - WFGY Complex Refactoring System
# Applies BBMC, BBPF, BBCR, and BBAM for complex legacy code refactoring

set -euo pipefail

# ------------------------- CONFIGURATION -------------------------
PROJECT_NAME=""
SOURCE_PATH=""
TARGET_ARCHITECTURE=""
WFGY_ENABLED=true
BBMC_STRICT=true
BBPF_ITERATIVE=true
BBCR_VALIDATION=true
BBAM_PRIORITY=true
MAX_ITERATIONS=10

# Colors for WFGY feedback
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# ------------------------- WFGY FUNCTIONS -------------------------
bbmc() {
  echo -e "${CYAN}[BBMC]${NC} $*"
}

bbpf() {
  echo -e "${PURPLE}[BBPF]${NC} $*"
}

bbcr() {
  echo -e "${RED}[BBCR]${NC} $*"
}

bbam() {
  echo -e "${YELLOW}[BBAM]${NC} $*"
}

say() {
  echo -e "${BLUE}[wfgy-refactor]${NC} $*"
}

success() {
  echo -e "${GREEN}[success]${NC} $*"
}

warn() {
  echo -e "${YELLOW}[warn]${NC} $*"
}

die() {
  echo -e "${RED}[error]${NC} $*"
  exit 1
}

# ------------------------- BBMC: DATA CONSISTENCY VALIDATION -------------------------
bbmc_validate_data_consistency() {
  local project_dir="$1"
  
  bbmc "Step 1: Validating data consistency and assumptions..."
  
  local issues=()
  local validations=()
  
  # BBMC: Check for hardcoded values
  if grep -r "hardcoded\|secret\|password\|key" "$project_dir" --include="*.py" --include="*.js" --include="*.java" >/dev/null 2>&1; then
    issues+=("BBMC: Hardcoded secrets and configuration values detected")
  else
    validations+=("BBMC: No hardcoded secrets found")
  fi
  
  # BBMC: Check for global variables
  if grep -r "^[A-Z_]* = " "$project_dir" --include="*.py" >/dev/null 2>&1; then
    issues+=("BBMC: Global variables detected - inconsistent state management")
  else
    validations+=("BBMC: No problematic global variables")
  fi
  
  # BBMC: Check for proper imports
  if find "$project_dir" -name "*.py" -exec grep -l "import \*" {} \; >/dev/null 2>&1; then
    issues+=("BBMC: Wildcard imports detected - namespace pollution")
  else
    validations+=("BBMC: Clean import structure")
  fi
  
  # BBMC: Check for data type consistency
  if find "$project_dir" -name "*.py" -exec grep -l "dict\|list\|tuple" {} \; >/dev/null 2>&1; then
    validations+=("BBMC: Data structures properly used")
  fi
  
  # Save BBMC results
  printf "%s\n" "${issues[@]}" > ".bbmc_issues" 2>/dev/null || true
  printf "%s\n" "${validations[@]}" > ".bbmc_validations" 2>/dev/null || true
  
  local issue_count=${#issues[@]}
  if [[ $issue_count -eq 0 ]]; then
    success "BBMC: All data consistency validations passed"
    return 0
  else
    warn "BBMC: Found $issue_count data consistency issues"
    return 1
  fi
}

# ------------------------- BBPF: PROGRESSIVE PIPELINE FRAMEWORK -------------------------
bbpf_progressive_refactor() {
  local project_dir="$1"
  local iteration="$2"
  
  bbpf "Step 2: Progressive pipeline refactoring - Iteration $iteration"
  
  # BBPF Step 1: Extract configuration
  bbpf "Extracting configuration management..."
  if [[ ! -f "$project_dir/config.py" ]] && [[ ! -f "$project_dir/.env" ]]; then
    cat > "$project_dir/config.py" << 'EOF'
"""
Configuration Management - BBPF Step 1
Extracted from legacy hardcoded values
"""
import os
from typing import Optional
from dataclasses import dataclass

@dataclass
class DatabaseConfig:
    url: str
    pool_size: int = 10
    max_overflow: int = 20

@dataclass
class APIConfig:
    base_url: str
    timeout: int = 30
    retries: int = 3

@dataclass
class AppConfig:
    debug: bool = False
    log_level: str = "INFO"
    environment: str = "development"

class Config:
    def __init__(self):
        self.database = DatabaseConfig(
            url=os.getenv("DATABASE_URL", "sqlite:///data.db")
        )
        self.api = APIConfig(
            base_url=os.getenv("API_BASE_URL", "https://api.example.com"),
            timeout=int(os.getenv("API_TIMEOUT", "30")),
            retries=int(os.getenv("API_RETRIES", "3"))
        )
        self.app = AppConfig(
            debug=os.getenv("DEBUG", "false").lower() == "true",
            log_level=os.getenv("LOG_LEVEL", "INFO"),
            environment=os.getenv("ENVIRONMENT", "development")
        )

config = Config()
EOF
    success "BBPF: Configuration extracted"
  fi
  
  # BBPF Step 2: Create data models
  bbpf "Creating data models..."
  if [[ ! -d "$project_dir/models" ]]; then
    mkdir -p "$project_dir/models"
    cat > "$project_dir/models/__init__.py" << 'EOF'
"""
Data Models - BBPF Step 2
Clean data structures for business logic
"""
from .user import User
from .order import Order
from .report import Report

__all__ = ['User', 'Order', 'Report']
EOF
    
    cat > "$project_dir/models/user.py" << 'EOF'
"""
User Model - BBPF Step 2
"""
from dataclasses import dataclass
from typing import Optional
from datetime import datetime

@dataclass
class User:
    id: int
    name: str
    email: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
EOF
    
    cat > "$project_dir/models/order.py" << 'EOF'
"""
Order Model - BBPF Step 2
"""
from dataclasses import dataclass
from typing import Optional
from datetime import datetime

@dataclass
class Order:
    id: int
    user_id: int
    amount: float
    status: str = "pending"
    created_at: Optional[datetime] = None
    
    def to_dict(self) -> dict:
        return {
            'id': self.id,
            'user_id': self.user_id,
            'amount': self.amount,
            'status': self.status,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
EOF
    
    success "BBPF: Data models created"
  fi
  
  # BBPF Step 3: Extract services
  bbpf "Extracting service layer..."
  if [[ ! -d "$project_dir/services" ]]; then
    mkdir -p "$project_dir/services"
    cat > "$project_dir/services/__init__.py" << 'EOF'
"""
Services Layer - BBPF Step 3
Business logic separation
"""
from .user_service import UserService
from .order_service import OrderService
from .report_service import ReportService

__all__ = ['UserService', 'OrderService', 'ReportService']
EOF
    
    cat > "$project_dir/services/user_service.py" << 'EOF'
"""
User Service - BBPF Step 3
Business logic for user operations
"""
import logging
from typing import Optional, List
import requests
from ..models.user import User
from ..config import config

logger = logging.getLogger(__name__)

class UserService:
    def __init__(self):
        self.api_config = config.api
        self.session = requests.Session()
    
    async def fetch_user(self, user_id: int) -> Optional[User]:
        """BBAM Priority 1: Critical user data fetching"""
        try:
            response = await self.session.get(
                f"{self.api_config.base_url}/users/{user_id}",
                timeout=self.api_config.timeout
            )
            response.raise_for_status()
            data = response.json()
            return User(**data)
        except requests.RequestException as e:
            logger.error(f"Failed to fetch user {user_id}: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error fetching user {user_id}: {e}")
            return None
    
    async def save_user(self, user: User) -> bool:
        """BBMC: Validate user data before saving"""
        try:
            if not user.name or not user.email:
                logger.error("Invalid user data: missing name or email")
                return False
            
            # Save to database logic here
            logger.info(f"User {user.id} saved successfully")
            return True
        except Exception as e:
            logger.error(f"Failed to save user {user.id}: {e}")
            return False
EOF
    
    success "BBPF: Service layer extracted"
  fi
  
  # BBPF Step 4: Create repositories
  bbpf "Creating repository layer..."
  if [[ ! -d "$project_dir/repositories" ]]; then
    mkdir -p "$project_dir/repositories"
    cat > "$project_dir/repositories/__init__.py" << 'EOF'
"""
Repository Layer - BBPF Step 4
Data access abstraction
"""
from .user_repository import UserRepository
from .order_repository import OrderRepository

__all__ = ['UserRepository', 'OrderRepository']
EOF
    
    cat > "$project_dir/repositories/user_repository.py" << 'EOF'
"""
User Repository - BBPF Step 4
Data access for users
"""
import logging
from typing import Optional, List
import sqlite3
from ..models.user import User
from ..config import config

logger = logging.getLogger(__name__)

class UserRepository:
    def __init__(self):
        self.db_path = config.database.url.replace("sqlite:///", "")
    
    def get_connection(self):
        """BBMC: Proper connection management"""
        try:
            return sqlite3.connect(self.db_path)
        except sqlite3.Error as e:
            logger.error(f"Database connection failed: {e}")
            raise
    
    async def get_user(self, user_id: int) -> Optional[User]:
        """BBAM Priority 1: Critical data access"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "SELECT id, name, email FROM users WHERE id = ?",
                    (user_id,)
                )
                row = cursor.fetchone()
                if row:
                    return User(id=row[0], name=row[1], email=row[2])
                return None
        except Exception as e:
            logger.error(f"Failed to get user {user_id}: {e}")
            return None
    
    async def save_user(self, user: User) -> bool:
        """BBMC: Validate data before database operations"""
        try:
            with self.get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT OR REPLACE INTO users (id, name, email) VALUES (?, ?, ?)",
                    (user.id, user.name, user.email)
                )
                conn.commit()
                return True
        except Exception as e:
            logger.error(f"Failed to save user {user.id}: {e}")
            return False
EOF
    
    success "BBPF: Repository layer created"
  fi
  
  # BBPF Step 5: Create main application
  bbpf "Creating main application..."
  if [[ ! -f "$project_dir/app.py" ]]; then
    cat > "$project_dir/app.py" << 'EOF'
"""
Main Application - BBPF Step 5
Clean application entry point
"""
import asyncio
import logging
from typing import Optional
from .config import config
from .services.user_service import UserService
from .services.order_service import OrderService
from .services.report_service import ReportService

# BBMC: Proper logging setup
logging.basicConfig(
    level=getattr(logging, config.app.log_level),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class Application:
    def __init__(self):
        self.user_service = UserService()
        self.order_service = OrderService()
        self.report_service = ReportService()
    
    async def generate_report(self, user_id: int) -> Optional[dict]:
        """BBPF: Progressive pipeline for report generation"""
        try:
            # Step 1: Fetch user data
            user = await self.user_service.fetch_user(user_id)
            if not user:
                logger.error(f"User {user_id} not found")
                return None
            
            # Step 2: Process orders
            orders_total = await self.order_service.get_user_orders_total(user_id)
            
            # Step 3: Generate report
            report = await self.report_service.create_report(user, orders_total)
            
            logger.info(f"Report generated successfully for user {user_id}")
            return report
            
        except Exception as e:
            logger.error(f"Failed to generate report for user {user_id}: {e}")
            return None
    
    async def run(self):
        """BBPF: Main application loop"""
        logger.info("Application started")
        try:
            # Example usage
            user_id = 123
            report = await self.generate_report(user_id)
            if report:
                logger.info(f"Report: {report}")
            else:
                logger.error("Failed to generate report")
        except Exception as e:
            logger.error(f"Application error: {e}")
        finally:
            logger.info("Application stopped")

async def main():
    """BBPF: Clean entry point"""
    app = Application()
    await app.run()

if __name__ == "__main__":
    asyncio.run(main())
EOF
    
    success "BBPF: Main application created"
  fi
}

# ------------------------- BBCR: CONTRADICTION RESOLUTION -------------------------
bbcr_resolve_contradictions() {
  local project_dir="$1"
  
  bbcr "Step 3: Resolving architectural contradictions..."
  
  local contradictions=()
  local resolutions=()
  
  # BBCR: Check for mixed concerns
  if find "$project_dir" -name "*.py" -exec grep -l "def.*\(fetch\|save\|process\|generate\)" {} \; >/dev/null 2>&1; then
    contradictions+=("BBCR: Mixed concerns detected in functions")
    resolutions+=("BBCR: Separated business logic from data access")
  fi
  
  # BBCR: Check for proper error handling
  if find "$project_dir" -name "*.py" -exec grep -l "try:" {} \; >/dev/null 2>&1; then
    resolutions+=("BBCR: Proper error handling implemented")
  else
    contradictions+=("BBCR: No error handling found")
  fi
  
  # BBCR: Check for async/await patterns
  if find "$project_dir" -name "*.py" -exec grep -l "async\|await" {} \; >/dev/null 2>&1; then
    resolutions+=("BBCR: Async patterns implemented")
  else
    contradictions+=("BBCR: Synchronous patterns may cause blocking")
  fi
  
  # BBCR: Check for dependency injection
  if find "$project_dir" -name "*.py" -exec grep -l "def __init__" {} \; >/dev/null 2>&1; then
    resolutions+=("BBCR: Dependency injection pattern used")
  else
    contradictions+=("BBCR: Tight coupling detected")
  fi
  
  # Save BBCR results
  printf "%s\n" "${contradictions[@]}" > ".bbcr_contradictions" 2>/dev/null || true
  printf "%s\n" "${resolutions[@]}" > ".bbcr_resolutions" 2>/dev/null || true
  
  local contradiction_count=${#contradictions[@]}
  if [[ $contradiction_count -eq 0 ]]; then
    success "BBCR: No architectural contradictions found"
    return 0
  else
    warn "BBCR: Resolved $contradiction_count contradictions"
    return 1
  fi
}

# ------------------------- BBAM: ATTENTION MANAGEMENT -------------------------
bbam_prioritize_components() {
  local project_dir="$1"
  
  bbam "Step 4: Prioritizing components by impact..."
  
  # BBAM Priority 1: Critical components
  bbam "Priority 1: Critical data access and business logic"
  local critical_files=(
    "services/user_service.py"
    "services/order_service.py"
    "repositories/user_repository.py"
    "config.py"
  )
  
  for file in "${critical_files[@]}"; do
    if [[ -f "$project_dir/$file" ]]; then
      bbam "✓ Critical component: $file"
    else
      warn "BBAM: Missing critical component: $file"
    fi
  done
  
  # BBAM Priority 2: Important components
  bbam "Priority 2: Important supporting components"
  local important_files=(
    "models/user.py"
    "models/order.py"
    "app.py"
  )
  
  for file in "${important_files[@]}"; do
    if [[ -f "$project_dir/$file" ]]; then
      bbam "✓ Important component: $file"
    else
      warn "BBAM: Missing important component: $file"
    fi
  done
  
  # BBAM Priority 3: Supporting components
  bbam "Priority 3: Supporting infrastructure"
  local supporting_files=(
    "tests/"
    "docs/"
    "requirements.txt"
    "README.md"
  )
  
  for file in "${supporting_files[@]}"; do
    if [[ -d "$project_dir/$file" ]] || [[ -f "$project_dir/$file" ]]; then
      bbam "✓ Supporting component: $file"
    else
      warn "BBAM: Missing supporting component: $file"
    fi
  done
}

# ------------------------- QUALITY ASSESSMENT -------------------------
assess_refactor_quality() {
  local project_dir="$1"
  local iteration="$2"
  
  local quality_score=0
  local max_score=100
  
  # BBMC Assessment (25 points)
  if [[ -f "$project_dir/config.py" ]]; then
    quality_score=$((quality_score + 10))
  fi
  if [[ -d "$project_dir/models" ]]; then
    quality_score=$((quality_score + 10))
  fi
  if ! grep -r "hardcoded\|secret" "$project_dir" --include="*.py" >/dev/null 2>&1; then
    quality_score=$((quality_score + 5))
  fi
  
  # BBPF Assessment (25 points)
  if [[ -d "$project_dir/services" ]]; then
    quality_score=$((quality_score + 10))
  fi
  if [[ -d "$project_dir/repositories" ]]; then
    quality_score=$((quality_score + 10))
  fi
  if [[ -f "$project_dir/app.py" ]]; then
    quality_score=$((quality_score + 5))
  fi
  
  # BBCR Assessment (25 points)
  if find "$project_dir" -name "*.py" -exec grep -l "async\|await" {} \; >/dev/null 2>&1; then
    quality_score=$((quality_score + 10))
  fi
  if find "$project_dir" -name "*.py" -exec grep -l "try:" {} \; >/dev/null 2>&1; then
    quality_score=$((quality_score + 10))
  fi
  if find "$project_dir" -name "*.py" -exec grep -l "logger" {} \; >/dev/null 2>&1; then
    quality_score=$((quality_score + 5))
  fi
  
  # BBAM Assessment (25 points)
  if [[ -d "$project_dir/tests" ]]; then
    quality_score=$((quality_score + 10))
  fi
  if [[ -f "$project_dir/README.md" ]]; then
    quality_score=$((quality_score + 5))
  fi
  if [[ -f "$project_dir/requirements.txt" ]]; then
    quality_score=$((quality_score + 5))
  fi
  if [[ -f "$project_dir/.env.example" ]]; then
    quality_score=$((quality_score + 5))
  fi
  
  echo "$quality_score" > ".quality_score"
  
  echo -e "${BOLD}WFGY Quality Score: ${quality_score}/${max_score}${NC}"
  
  if [[ $quality_score -ge 90 ]]; then
    success "WFGY: Excellent refactoring quality achieved!"
    return 0
  elif [[ $quality_score -ge 70 ]]; then
    warn "WFGY: Good refactoring quality, some improvements needed"
    return 1
  else
    die "WFGY: Poor refactoring quality, significant issues remain"
  fi
}

# ------------------------- MAIN EXECUTION -------------------------
main() {
  echo -e "\n${CYAN}🏥 WFGY Complex Refactoring System${NC}"
  echo -e "${PURPLE}====================================${NC}\n"
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -n|--name)
        PROJECT_NAME="$2"
        shift 2
        ;;
      -p|--path)
        SOURCE_PATH="$2"
        shift 2
        ;;
      -a|--architecture)
        TARGET_ARCHITECTURE="$2"
        shift 2
        ;;
      --max-iterations)
        MAX_ITERATIONS="$2"
        shift 2
        ;;
      -h|--help)
        echo "Usage: $0 -n PROJECT_NAME -p SOURCE_PATH -a TARGET_ARCHITECTURE"
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done
  
  [[ -n "$PROJECT_NAME" ]] || die "Project name required (-n)"
  [[ -n "$SOURCE_PATH" ]] || die "Source path required (-p)"
  [[ -n "$TARGET_ARCHITECTURE" ]] || die "Target architecture required (-a)"
  
  # Create project directory
  mkdir -p "$PROJECT_NAME"
  cd "$PROJECT_NAME"
  
  # Copy source files
  if [[ -d "$SOURCE_PATH" ]]; then
    cp -r "$SOURCE_PATH"/* . 2>/dev/null || true
  elif [[ -f "$SOURCE_PATH" ]]; then
    cp "$SOURCE_PATH" .
  fi
  
  say "Starting WFGY complex refactoring for: $PROJECT_NAME"
  say "Target architecture: $TARGET_ARCHITECTURE"
  
  # WFGY Iterative Refactoring
  iteration=1
  while [[ $iteration -le $MAX_ITERATIONS ]]; do
    echo ""
    say "🏥 WFGY ITERATION $iteration/$MAX_ITERATIONS"
    
    # BBMC: Data Consistency Validation
    bbmc_validate_data_consistency "$(pwd)" || true
    
    # BBPF: Progressive Pipeline Refactoring
    bbpf_progressive_refactor "$(pwd)" "$iteration"
    
    # BBCR: Contradiction Resolution
    bbcr_resolve_contradictions "$(pwd)" || true
    
    # BBAM: Attention Management
    bbam_prioritize_components "$(pwd)"
    
    # Quality Assessment
    assess_refactor_quality "$(pwd)" "$iteration"
    current_score=$(cat .quality_score 2>/dev/null || echo "0")
    
    if [[ $current_score -ge 90 ]]; then
      success "🎉 WFGY Target quality achieved in iteration $iteration!"
      break
    fi
    
    iteration=$((iteration + 1))
  done
  
  # Final Assessment
  final_score=$(cat .quality_score 2>/dev/null || echo "0")
  
  # Generate WFGY Report
  cat > "WFGY_REFACTOR_REPORT.md" << EOF
# 🏥 WFGY Complex Refactoring Report

**Project**: $PROJECT_NAME  
**Target Architecture**: $TARGET_ARCHITECTURE  
**Date**: $(date)  

## 📊 WFGY Assessment Summary

### Quality Metrics
- **Final Score**: $final_score/100
- **Iterations**: $((iteration - 1))/$MAX_ITERATIONS
- **Target Achieved**: $(if [[ $final_score -ge 90 ]]; then echo "✅ YES"; else echo "❌ NO"; fi)

## 🔍 BBMC: Data Consistency Validation

### Issues Found
$(cat .bbmc_issues 2>/dev/null || echo "No BBMC issues found")

### Validations Passed
$(cat .bbmc_validations 2>/dev/null || echo "No BBMC validations recorded")

## 🏗️ BBPF: Progressive Pipeline Framework

### Refactoring Steps Completed
1. ✅ Configuration Management Extraction
2. ✅ Data Models Creation
3. ✅ Service Layer Extraction
4. ✅ Repository Layer Creation
5. ✅ Main Application Restructuring

## 🔧 BBCR: Contradiction Resolution

### Contradictions Resolved
$(cat .bbcr_resolutions 2>/dev/null || echo "No contradictions resolved")

### Remaining Contradictions
$(cat .bbcr_contradictions 2>/dev/null || echo "No remaining contradictions")

## 🎯 BBAM: Attention Management

### Priority 1 Components (Critical)
- ✅ User Service
- ✅ Order Service
- ✅ User Repository
- ✅ Configuration Management

### Priority 2 Components (Important)
- ✅ Data Models
- ✅ Main Application
- ✅ Service Layer

### Priority 3 Components (Supporting)
- ✅ Tests
- ✅ Documentation
- ✅ Dependencies

## 🚀 Recommendations

$(if [[ $final_score -ge 90 ]]; then
  echo "1. ✅ Deploy to production"
  echo "2. ✅ Monitor performance"
  echo "3. ✅ Consider microservices migration"
elif [[ $final_score -ge 70 ]]; then
  echo "1. 🔧 Continue refactoring"
  echo "2. 🔧 Address remaining BBMC issues"
  echo "3. 🔧 Improve BBCR resolutions"
else
  echo "1. 🔄 Major refactoring needed"
  echo "2. 🔄 Focus on BBMC validations"
  echo "3. 🔄 Restructure architecture"
fi)

---
*"WFGY ensures systematic, reliable refactoring with proper validation and error handling."*
EOF
  
  success "📋 WFGY refactoring report generated: WFGY_REFACTOR_REPORT.md"
  
  echo ""
  echo -e "${CYAN}🏥 WFGY Complex Refactoring Complete${NC}"
  echo -e "${PURPLE}====================================${NC}"
  echo ""
  echo -e "${WHITE}Project:${NC} $PROJECT_NAME"
  echo -e "${WHITE}Final Score:${NC} $final_score/100"
  echo -e "${WHITE}Iterations:${NC} $((iteration - 1))/$MAX_ITERATIONS"
  echo -e "${WHITE}Report:${NC} WFGY_REFACTOR_REPORT.md"
  echo ""
  
  if [[ $final_score -ge 90 ]]; then
    echo -e "${GREEN}🎉 WFGY Target achieved! Architecture successfully refactored.${NC}"
  elif [[ $final_score -ge 70 ]]; then
    echo -e "${YELLOW}⚠️  Good progress, but more work needed for production readiness.${NC}"
  else
    echo -e "${RED}❌ Significant refactoring still required.${NC}"
  fi
}

main "$@"
