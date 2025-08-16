#!/bin/bash

# 18_wfgy_background_autonomous.sh - WFGY Background Autonomous System
# Runs autonomous learning system in background with continuous monitoring

set -euo pipefail

# Configuration
PROJECT_NAME=""
SOURCE_PATH=""
TARGET_ARCHITECTURE=""
PROJECT_TYPE=""
MAX_ITERATIONS=100
TARGET_SCORE=95
BACKGROUND_MODE=true
AUTO_LEARNING=true
SELF_IMPROVEMENT=true
MONITOR_INTERVAL=30
LOG_FILE="autonomous_learning.log"
PID_FILE="autonomous_learning.pid"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Functions
ai() { echo -e "${BLUE}[AI-BACKGROUND]${NC} $*"; }
success() { echo -e "${GREEN}[success]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
die() { echo -e "${RED}[error]${NC} $*"; exit 1; }

# Start Background Autonomous Learning
start_background_learning() {
  ai "🚀 Starting Background Autonomous Learning System..."
  
  # Check if already running
  if [[ -f "$PID_FILE" ]]; then
    local pid=$(cat "$PID_FILE" 2>/dev/null)
    if ps -p "$pid" >/dev/null 2>&1; then
      warn "Autonomous learning already running with PID: $pid"
      return 1
    else
      rm -f "$PID_FILE"
    fi
  fi
  
  # Start autonomous learning in background
  nohup ./scripts/17_wfgy_autonomous_learning.sh \
    -n "$PROJECT_NAME" \
    -p "$SOURCE_PATH" \
    -a "$TARGET_ARCHITECTURE" \
    -t "$PROJECT_TYPE" \
    --target-score "$TARGET_SCORE" \
    --max-iterations "$MAX_ITERATIONS" \
    --background \
    > "$LOG_FILE" 2>&1 &
  
  local pid=$!
  echo "$pid" > "$PID_FILE"
  
  success "Background autonomous learning started with PID: $pid"
  success "Log file: $LOG_FILE"
  success "PID file: $PID_FILE"
  
  return 0
}

# Stop Background Autonomous Learning
stop_background_learning() {
  ai "🛑 Stopping Background Autonomous Learning System..."
  
  if [[ -f "$PID_FILE" ]]; then
    local pid=$(cat "$PID_FILE")
    if ps -p "$pid" >/dev/null 2>&1; then
      kill "$pid" 2>/dev/null
      success "Stopped autonomous learning process (PID: $pid)"
    else
      warn "Process not running (PID: $pid)"
    fi
    rm -f "$PID_FILE"
  else
    warn "No PID file found"
  fi
}

# Monitor Background Learning
monitor_background_learning() {
  ai "📊 Monitoring Background Autonomous Learning..."
  
  if [[ ! -f "$PID_FILE" ]]; then
    warn "No autonomous learning process found"
    return 1
  fi
  
  local pid=$(cat "$PID_FILE")
  if ! ps -p "$pid" >/dev/null 2>&1; then
    warn "Process not running (PID: $pid)"
    rm -f "$PID_FILE"
    return 1
  fi
  
  # Show current status
  echo ""
  echo -e "${CYAN}📊 Background Autonomous Learning Status${NC}"
  echo -e "${PURPLE}====================================${NC}"
  echo ""
  echo -e "${WHITE}Process ID:${NC} $pid"
  echo -e "${WHITE}Status:${NC} Running"
  echo -e "${WHITE}Log File:${NC} $LOG_FILE"
  echo -e "${WHITE}PID File:${NC} $PID_FILE"
  echo ""
  
  # Show recent log entries
  if [[ -f "$LOG_FILE" ]]; then
    echo -e "${WHITE}Recent Log Entries:${NC}"
    echo -e "${PURPLE}==================${NC}"
    tail -20 "$LOG_FILE" | while IFS= read -r line; do
      echo "  $line"
    done
    echo ""
  fi
  
  # Check for completion
  if grep -q "AUTONOMOUS SUCCESS" "$LOG_FILE" 2>/dev/null; then
    success "🎉 Autonomous learning completed successfully!"
    return 0
  fi
  
  return 0
}

# Continuous Monitoring Loop
continuous_monitor() {
  ai "🔄 Starting continuous monitoring (interval: ${MONITOR_INTERVAL}s)..."
  
  while true; do
    monitor_background_learning
    
    # Check if process is still running
    if [[ -f "$PID_FILE" ]]; then
      local pid=$(cat "$PID_FILE")
      if ! ps -p "$pid" >/dev/null 2>&1; then
        warn "Process stopped unexpectedly"
        break
      fi
    else
      warn "PID file not found, stopping monitoring"
      break
    fi
    
    # Check for completion
    if grep -q "AUTONOMOUS SUCCESS" "$LOG_FILE" 2>/dev/null; then
      success "🎉 Autonomous learning completed successfully!"
      break
    fi
    
    sleep "$MONITOR_INTERVAL"
  done
}

# Show Learning Progress
show_progress() {
  ai "📈 Showing Learning Progress..."
  
  if [[ ! -f "$LOG_FILE" ]]; then
    warn "No log file found"
    return 1
  fi
  
  echo ""
  echo -e "${CYAN}📈 Autonomous Learning Progress${NC}"
  echo -e "${PURPLE}============================${NC}"
  echo ""
  
  # Extract scores from log
  local scores=$(grep "AUTONOMOUS SCORE:" "$LOG_FILE" | tail -10)
  if [[ -n "$scores" ]]; then
    echo -e "${WHITE}Recent Scores:${NC}"
    echo "$scores" | while IFS= read -r line; do
      echo "  $line"
    done
    echo ""
  fi
  
  # Show learning insights
  if [[ -f "autonomous-learning-test/.learning_insights.log" ]]; then
    echo -e "${WHITE}Learning Insights:${NC}"
    tail -5 "autonomous-learning-test/.learning_insights.log" | while IFS= read -r line; do
      echo "  $line"
    done
    echo ""
  fi
  
  # Show knowledge progress
  if [[ -f "autonomous-learning-test/.knowledge_progress.log" ]]; then
    echo -e "${WHITE}Knowledge Progress:${NC}"
    tail -5 "autonomous-learning-test/.knowledge_progress.log" | while IFS= read -r line; do
      echo "  $line"
    done
    echo ""
  fi
}

# Main execution
main() {
  echo -e "\n${CYAN}🧠 WFGY Background Autonomous Learning System${NC}"
  echo -e "${PURPLE}============================================${NC}\n"
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      start)
        COMMAND="start"
        shift
        ;;
      stop)
        COMMAND="stop"
        shift
        ;;
      monitor)
        COMMAND="monitor"
        shift
        ;;
      progress)
        COMMAND="progress"
        shift
        ;;
      continuous)
        COMMAND="continuous"
        shift
        ;;
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
      -t|--type)
        PROJECT_TYPE="$2"
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
      --interval)
        MONITOR_INTERVAL="$2"
        shift 2
        ;;
      -h|--help)
        echo "Usage: $0 {start|stop|monitor|progress|continuous} [options]"
        echo ""
        echo "Commands:"
        echo "  start       Start background autonomous learning"
        echo "  stop        Stop background autonomous learning"
        echo "  monitor     Monitor current status"
        echo "  progress    Show learning progress"
        echo "  continuous  Start continuous monitoring"
        echo ""
        echo "Options:"
        echo "  -n, --name PROJECT_NAME        Project name"
        echo "  -p, --path SOURCE_PATH         Source path"
        echo "  -a, --architecture ARCH        Target architecture"
        echo "  -t, --type TYPE                Project type"
        echo "  --target-score SCORE           Target score (default: 95)"
        echo "  --max-iterations ITERATIONS    Max iterations (default: 100)"
        echo "  --interval SECONDS             Monitor interval (default: 30)"
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done
  
  # Set defaults
  PROJECT_NAME=${PROJECT_NAME:-"autonomous-background"}
  SOURCE_PATH=${SOURCE_PATH:-"./complex-refactor-test"}
  TARGET_ARCHITECTURE=${TARGET_ARCHITECTURE:-"Background autonomous architecture"}
  PROJECT_TYPE=${PROJECT_TYPE:-"general"}
  
  # Execute command
  case "${COMMAND:-}" in
    start)
      start_background_learning
      ;;
    stop)
      stop_background_learning
      ;;
    monitor)
      monitor_background_learning
      ;;
    progress)
      show_progress
      ;;
    continuous)
      continuous_monitor
      ;;
    *)
      die "Command required: start|stop|monitor|progress|continuous"
      ;;
  esac
}

main "$@"
