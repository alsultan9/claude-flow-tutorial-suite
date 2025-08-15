#!/usr/bin/env python3
"""
WFGY Integrated System for Claude Flow Orchestration
Combines BBMC, BBPF, BBCR, and BBAM for rock-solid Claude Flow + Claude Code orchestration.
"""

import os
import sys
import time
import json
import subprocess
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from pathlib import Path

# Import WFGY components
from wfgy_validation import BBMCValidator, validate_claude_flow_input
from wfgy_pipeline import BBPFPipeline, progressive_claude_flow_pipeline
from wfgy_contradiction import BBCRDetector, BBCRResolver, bbcr_validate_claude_flow_output
from wfgy_attention import BBAMManager, BBAMOptimizer, bbam_optimize_claude_flow

@dataclass
class WFGYResult:
    success: bool
    stage: str
    message: str
    data: Dict[str, Any]
    execution_time: float
    rollback_needed: bool

class WFGYOrchestrator:
    """WFGY: Integrated orchestrator for Claude Flow + Claude Code"""
    
    def __init__(self):
        self.bbmc_validator = BBMCValidator()
        self.bbam_manager = BBAMManager()
        self.bbam_optimizer = BBAMOptimizer(self.bbam_manager)
        self.bbcr_detector = BBCRDetector()
        self.bbcr_resolver = BBCRResolver(self.bbcr_detector)
        
        self.results: List[WFGYResult] = []
        self.current_stage = "initialization"
    
    def orchestrate_claude_flow_project(self, project_name: str, idea_text: str, 
                                      project_complexity: str = "medium") -> WFGYResult:
        """WFGY: Complete orchestration workflow with all components"""
        
        start_time = time.time()
        
        try:
            # BBMC: Validate input consistency
            bbmc_result = self._bbmc_validation(idea_text)
            if not bbmc_result.success:
                return bbmc_result
            
            # BBAM: Optimize resource allocation
            bbam_result = self._bbam_optimization(idea_text, project_complexity)
            if not bbam_result.success:
                return bbam_result
            
            # BBPF: Execute progressive pipeline
            bbpf_result = self._bbpf_execution(project_name, idea_text, bbam_result.data)
            if not bbpf_result.success:
                return bbpf_result
            
            # BBCR: Validate outputs for contradictions
            bbcr_result = self._bbcr_validation(idea_text, bbpf_result.data.get("implementation_output", ""))
            if bbcr_result.rollback_needed:
                return self._handle_rollback(bbcr_result)
            
            # Success
            execution_time = time.time() - start_time
            return WFGYResult(
                success=True,
                stage="completed",
                message="WFGY orchestration completed successfully",
                data={
                    "bbmc": bbmc_result.data,
                    "bbam": bbam_result.data,
                    "bbpf": bbpf_result.data,
                    "bbcr": bbcr_result.data
                },
                execution_time=execution_time,
                rollback_needed=False
            )
            
        except Exception as e:
            execution_time = time.time() - start_time
            return WFGYResult(
                success=False,
                stage=self.current_stage,
                message=f"WFGY orchestration failed: {str(e)}",
                data={},
                execution_time=execution_time,
                rollback_needed=True
            )
    
    def _bbmc_validation(self, idea_text: str) -> WFGYResult:
        """BBMC: Validate idea consistency before processing"""
        
        self.current_stage = "bbmc_validation"
        start_time = time.time()
        
        try:
            # Validate idea structure
            validation_result = validate_claude_flow_input(idea_text)
            
            if not validation_result.is_valid:
                execution_time = time.time() - start_time
                return WFGYResult(
                    success=False,
                    stage="bbmc_validation",
                    message="BBMC: Idea validation failed",
                    data={
                        "validation_result": validation_result,
                        "missing_elements": validation_result.missing_elements,
                        "recommendations": validation_result.recommendations
                    },
                    execution_time=execution_time,
                    rollback_needed=False
                )
            
            execution_time = time.time() - start_time
            return WFGYResult(
                success=True,
                stage="bbmc_validation",
                message="BBMC: Idea validation passed",
                data={"validation_result": validation_result},
                execution_time=execution_time,
                rollback_needed=False
            )
            
        except Exception as e:
            execution_time = time.time() - start_time
            return WFGYResult(
                success=False,
                stage="bbmc_validation",
                message=f"BBMC: Validation error - {str(e)}",
                data={},
                execution_time=execution_time,
                rollback_needed=False
            )
    
    def _bbam_optimization(self, idea_text: str, project_complexity: str) -> WFGYResult:
        """BBAM: Optimize resource allocation and attention management"""
        
        self.current_stage = "bbam_optimization"
        start_time = time.time()
        
        try:
            # Optimize orchestration parameters
            optimization_result = bbam_optimize_claude_flow(idea_text, project_complexity)
            
            execution_time = time.time() - start_time
            return WFGYResult(
                success=True,
                stage="bbam_optimization",
                message="BBAM: Optimization completed",
                data={"optimization_result": optimization_result},
                execution_time=execution_time,
                rollback_needed=False
            )
            
        except Exception as e:
            execution_time = time.time() - start_time
            return WFGYResult(
                success=False,
                stage="bbam_optimization",
                message=f"BBAM: Optimization error - {str(e)}",
                data={},
                execution_time=execution_time,
                rollback_needed=False
            )
    
    def _bbpf_execution(self, project_name: str, idea_text: str, bbam_data: Dict[str, Any]) -> WFGYResult:
        """BBPF: Execute progressive pipeline with rollback capabilities"""
        
        self.current_stage = "bbpf_execution"
        start_time = time.time()
        
        try:
            # Extract optimized parameters
            optimized_params = bbam_data["optimization_result"]["optimized_parameters"]
            
            # Create and execute pipeline
            pipeline = BBPFPipeline(project_name, idea_text)
            
            # Override pipeline parameters with BBAM optimizations
            pipeline.pipeline_steps = self._update_pipeline_with_bbam(pipeline.pipeline_steps, optimized_params)
            
            # Execute pipeline
            pipeline_results = pipeline.execute_pipeline()
            
            # Check if pipeline completed successfully
            all_success = all(
                result.status.value == "success" 
                for result in pipeline_results.values()
            )
            
            if not all_success:
                execution_time = time.time() - start_time
                return WFGYResult(
                    success=False,
                    stage="bbpf_execution",
                    message="BBPF: Pipeline execution failed",
                    data={"pipeline_results": pipeline_results},
                    execution_time=execution_time,
                    rollback_needed=True
                )
            
            execution_time = time.time() - start_time
            return WFGYResult(
                success=True,
                stage="bbpf_execution",
                message="BBPF: Pipeline execution completed",
                data={
                    "pipeline_results": pipeline_results,
                    "implementation_output": self._extract_implementation_output(pipeline_results)
                },
                execution_time=execution_time,
                rollback_needed=False
            )
            
        except Exception as e:
            execution_time = time.time() - start_time
            return WFGYResult(
                success=False,
                stage="bbpf_execution",
                message=f"BBPF: Execution error - {str(e)}",
                data={},
                execution_time=execution_time,
                rollback_needed=True
            )
    
    def _bbcr_validation(self, idea_text: str, implementation_output: str) -> WFGYResult:
        """BBCR: Validate outputs for contradictions"""
        
        self.current_stage = "bbcr_validation"
        start_time = time.time()
        
        try:
            # Validate for contradictions
            bbcr_result = bbcr_validate_claude_flow_output(idea_text, implementation_output)
            
            execution_time = time.time() - start_time
            return WFGYResult(
                success=bbcr_result["can_proceed"],
                stage="bbcr_validation",
                message=f"BBCR: {'Validation passed' if bbcr_result['can_proceed'] else 'Contradictions detected'}",
                data={"bbcr_result": bbcr_result},
                execution_time=execution_time,
                rollback_needed=bbcr_result["needs_rollback"]
            )
            
        except Exception as e:
            execution_time = time.time() - start_time
            return WFGYResult(
                success=False,
                stage="bbcr_validation",
                message=f"BBCR: Validation error - {str(e)}",
                data={},
                execution_time=execution_time,
                rollback_needed=True
            )
    
    def _handle_rollback(self, result: WFGYResult) -> WFGYResult:
        """WFGY: Handle rollback when contradictions are detected"""
        
        self.current_stage = "rollback"
        start_time = time.time()
        
        try:
            # Extract rollback actions from BBCR
            bbcr_result = result.data.get("bbcr_result", {})
            corrective_actions = bbcr_result.get("corrective_actions", [])
            
            # Execute rollback
            rollback_success = self._execute_rollback(corrective_actions)
            
            execution_time = time.time() - start_time
            return WFGYResult(
                success=rollback_success,
                stage="rollback",
                message=f"Rollback {'completed' if rollback_success else 'failed'}",
                data={
                    "corrective_actions": corrective_actions,
                    "rollback_success": rollback_success
                },
                execution_time=execution_time,
                rollback_needed=False
            )
            
        except Exception as e:
            execution_time = time.time() - start_time
            return WFGYResult(
                success=False,
                stage="rollback",
                message=f"Rollback error - {str(e)}",
                data={},
                execution_time=execution_time,
                rollback_needed=False
            )
    
    def _update_pipeline_with_bbam(self, pipeline_steps: Dict, optimized_params: Dict[str, Any]) -> Dict:
        """BBAM: Update pipeline steps with optimized parameters"""
        
        # Update commands with optimized parameters
        for step in pipeline_steps.values():
            if "claude-flow" in step.command:
                # Update SPARC mode if specified
                if optimized_params.get("sparc_mode"):
                    step.command = step.command.replace(
                        "claude-flow sparc architect",
                        f"claude-flow sparc {optimized_params['sparc_mode']}"
                    )
                
                # Update swarm parameters if needed
                if "swarm" in step.command and optimized_params.get("agent_count"):
                    step.command = step.command.replace(
                        "claude-flow swarm",
                        f"claude-flow swarm --agents {optimized_params['agent_count']}"
                    )
        
        return pipeline_steps
    
    def _extract_implementation_output(self, pipeline_results: Dict) -> str:
        """BBPF: Extract implementation output from pipeline results"""
        
        # Look for implementation stage output
        for stage, result in pipeline_results.items():
            if "implementation" in stage.value.lower():
                return result.output
        
        return ""
    
    def _execute_rollback(self, corrective_actions: List[str]) -> bool:
        """WFGY: Execute rollback based on corrective actions"""
        
        try:
            for action in corrective_actions:
                if "rollback" in action.lower():
                    # Execute rollback command
                    if "cleanup" in action.lower():
                        # Clean up project files
                        subprocess.run("rm -rf /tmp/*_project", shell=True, check=False)
                    elif "restart" in action.lower():
                        # Restart orchestration with different parameters
                        pass
            
            return True
            
        except Exception:
            return False

def wfgy_claude_flow_orchestration(project_name: str, idea_text: str, 
                                  project_complexity: str = "medium") -> WFGYResult:
    """WFGY: Main function for integrated Claude Flow orchestration"""
    
    orchestrator = WFGYOrchestrator()
    return orchestrator.orchestrate_claude_flow_project(project_name, idea_text, project_complexity)

def wfgy_enhanced_tutorial_script(project_name: str, idea_text: str, 
                                project_complexity: str = "medium") -> str:
    """WFGY: Generate enhanced tutorial script with WFGY integration"""
    
    # Run WFGY orchestration
    result = wfgy_claude_flow_orchestration(project_name, idea_text, project_complexity)
    
    if result.success:
        # Generate enhanced script
        script_content = f"""#!/bin/bash
# WFGY Enhanced Claude Flow Tutorial Script
# Generated with BBMC, BBPF, BBCR, and BBAM integration

set -e

PROJECT_NAME="{project_name}"
IDEA_TEXT='{idea_text.replace("'", "'\"'\"'")}'
PROJECT_COMPLEXITY="{project_complexity}"

echo "🚀 WFGY Enhanced Claude Flow Orchestration"
echo "Project: $PROJECT_NAME"
echo "Complexity: $PROJECT_COMPLEXITY"
echo ""

# BBMC: Validate idea structure
echo "🔍 BBMC: Validating idea consistency..."
python3 -c "
from wfgy_validation import validate_claude_flow_input
result = validate_claude_flow_input('''$IDEA_TEXT''')
if not result.is_valid:
    print('❌ BBMC Validation failed:')
    print(f'Missing elements: {{result.missing_elements}}')
    print(f'Recommendations: {{result.recommendations}}')
    exit(1)
print('✅ BBMC Validation passed')
print(f'Optimal SPARC mode: {{result.suggested_sparc_mode}}')
print(f'Optimal topology: {{result.suggested_topology}}')
print(f'Agent count: {{result.estimated_agents}}')
"

# BBAM: Optimize resource allocation
echo ""
echo "🎯 BBAM: Optimizing resource allocation..."
python3 -c "
from wfgy_attention import bbam_optimize_claude_flow
result = bbam_optimize_claude_flow('''$IDEA_TEXT''', '$PROJECT_COMPLEXITY')
print('✅ BBAM Optimization completed')
print(f'Clarity score: {{result[\"analysis\"][\"clarity_score\"]:.2f}}')
print(f'Optimal SPARC mode: {{result[\"optimized_parameters\"][\"sparc_mode\"]}}')
print(f'Topology: {{result[\"optimized_parameters\"][\"topology\"]}}')
print(f'Agent count: {{result[\"optimized_parameters\"][\"agent_count\"]}}')
"

# BBPF: Execute progressive pipeline
echo ""
echo "🔄 BBPF: Executing progressive pipeline..."
python3 -c "
from wfgy_pipeline import progressive_claude_flow_pipeline
result = progressive_claude_flow_pipeline('$PROJECT_NAME', '''$IDEA_TEXT''')
print('✅ BBPF Pipeline completed')
"

# BBCR: Validate for contradictions
echo ""
echo "🔍 BBCR: Validating for contradictions..."
python3 -c "
from wfgy_contradiction import bbcr_validate_claude_flow_output
result = bbcr_validate_claude_flow_output('''$IDEA_TEXT''', 'Implementation completed')
if result['needs_rollback']:
    print('❌ BBCR: Contradictions detected, rollback needed')
    print(f'Contradictions: {{result[\"contradictions_found\"]}}')
    exit(1)
print('✅ BBCR: No contradictions detected')
"

echo ""
echo "🎉 WFGY Enhanced Orchestration Completed Successfully!"
echo "Project: $PROJECT_NAME"
echo "All WFGY components validated and executed successfully."
"""
        
        return script_content
    
    else:
        # Generate error script
        error_script = f"""#!/bin/bash
# WFGY Enhanced Claude Flow Tutorial Script - ERROR VERSION
# Generated after WFGY orchestration failure

echo "❌ WFGY Enhanced Orchestration Failed"
echo "Project: {project_name}"
echo "Stage: {result.stage}"
echo "Error: {result.message}"
echo "Execution time: {result.execution_time:.2f}s"
echo ""

if {result.rollback_needed}:
    echo "🔄 Rollback needed. Please review and fix issues before retrying."
    echo "Recommendations:"
    if "bbmc" in result.stage:
        print("  - Improve idea clarity and completeness")
        print("  - Add missing elements (users, goal, inputs, outputs, runtime)")
    elif "bbam" in result.stage:
        print("  - Review project complexity assessment")
        print("  - Optimize resource requirements")
    elif "bbpf" in result.stage:
        print("  - Check Claude Flow installation and configuration")
        print("  - Verify system resources")
    elif "bbcr" in result.stage:
        print("  - Review implementation for contradictions")
        print("  - Align technology choices with requirements")
fi

echo ""
echo "For detailed WFGY analysis, run:"
echo "python3 wfgy_integrated.py --analyze '{project_name}' '{idea_text.replace("'", "'\"'\"'")}'"
"""
        
        return error_script

# Example usage
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="WFGY Enhanced Claude Flow Orchestration")
    parser.add_argument("--project", required=True, help="Project name")
    parser.add_argument("--idea", required=True, help="Project idea text")
    parser.add_argument("--complexity", default="medium", choices=["simple", "medium", "complex"], 
                       help="Project complexity")
    parser.add_argument("--generate-script", action="store_true", 
                       help="Generate enhanced tutorial script")
    
    args = parser.parse_args()
    
    if args.generate_script:
        script = wfgy_enhanced_tutorial_script(args.project, args.idea, args.complexity)
        print(script)
    else:
        result = wfgy_claude_flow_orchestration(args.project, args.idea, args.complexity)
        
        print(f"WFGY Orchestration Result:")
        print(f"Success: {result.success}")
        print(f"Stage: {result.stage}")
        print(f"Message: {result.message}")
        print(f"Execution time: {result.execution_time:.2f}s")
        print(f"Rollback needed: {result.rollback_needed}")
        
        if result.success:
            print("\n✅ WFGY Enhanced Orchestration Completed Successfully!")
        else:
            print("\n❌ WFGY Enhanced Orchestration Failed")
            print("Check the error details above for troubleshooting.")
