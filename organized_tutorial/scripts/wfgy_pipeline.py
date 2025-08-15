#!/usr/bin/env python3
"""
WFGY BBPF: Progressive Pipeline Framework for Claude Flow Orchestration
Designs orchestration pipelines step-by-step with clear dependencies and rollback points.
"""

import os
import json
import subprocess
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from enum import Enum
from pathlib import Path

class PipelineStage(Enum):
    VALIDATION = "validation"
    ANALYSIS = "analysis"
    PLANNING = "planning"
    IMPLEMENTATION = "implementation"
    TESTING = "testing"
    DEPLOYMENT = "deployment"

class PipelineStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    ROLLBACK = "rollback"

@dataclass
class PipelineStep:
    stage: PipelineStage
    command: str
    dependencies: List[PipelineStage]
    rollback_command: Optional[str] = None
    validation_check: Optional[str] = None
    timeout: int = 300  # 5 minutes default

@dataclass
class PipelineResult:
    stage: PipelineStage
    status: PipelineStatus
    output: str
    error: Optional[str] = None
    execution_time: float = 0.0

class BBPFPipeline:
    """BBPF: Progressive pipeline with rollback capabilities"""
    
    def __init__(self, project_name: str, idea_text: str):
        self.project_name = project_name
        self.idea_text = idea_text
        self.project_dir = Path(f"/tmp/{project_name}")
        self.results: Dict[PipelineStage, PipelineResult] = {}
        self.current_stage = PipelineStage.VALIDATION
        
        # Define pipeline steps with dependencies
        self.pipeline_steps = self._define_pipeline_steps()
    
    def _define_pipeline_steps(self) -> Dict[PipelineStage, PipelineStep]:
        """BBPF: Define pipeline steps with clear dependencies"""
        
        return {
            PipelineStage.VALIDATION: PipelineStep(
                stage=PipelineStage.VALIDATION,
                command="python3 wfgy_validation.py",
                dependencies=[],
                validation_check="validate_idea_structure",
                rollback_command="echo 'Validation failed - cannot proceed'"
            ),
            
            PipelineStage.ANALYSIS: PipelineStep(
                stage=PipelineStage.ANALYSIS,
                command="claude-flow sparc architect 'Analyze requirements and suggest architecture'",
                dependencies=[PipelineStage.VALIDATION],
                validation_check="check_analysis_output",
                rollback_command="echo 'Analysis failed - rollback to validation'"
            ),
            
            PipelineStage.PLANNING: PipelineStep(
                stage=PipelineStage.PLANNING,
                command="claude-flow swarm 'Create detailed implementation plan'",
                dependencies=[PipelineStage.ANALYSIS],
                validation_check="check_planning_output",
                rollback_command="echo 'Planning failed - rollback to analysis'"
            ),
            
            PipelineStage.IMPLEMENTATION: PipelineStep(
                stage=PipelineStage.IMPLEMENTATION,
                command="claude-flow swarm 'Implement the project according to plan'",
                dependencies=[PipelineStage.PLANNING],
                validation_check="check_implementation_output",
                rollback_command="rm -rf /tmp/{project_name} && echo 'Implementation rolled back'"
            ),
            
            PipelineStage.TESTING: PipelineStep(
                stage=PipelineStage.TESTING,
                command="claude-flow sparc tdd 'Run comprehensive tests'",
                dependencies=[PipelineStage.IMPLEMENTATION],
                validation_check="check_testing_output",
                rollback_command="echo 'Testing failed - rollback to implementation'"
            ),
            
            PipelineStage.DEPLOYMENT: PipelineStep(
                stage=PipelineStage.DEPLOYMENT,
                command="claude-flow sparc devops 'Deploy and verify'",
                dependencies=[PipelineStage.TESTING],
                validation_check="check_deployment_output",
                rollback_command="echo 'Deployment failed - rollback to testing'"
            )
        }
    
    def execute_pipeline(self) -> Dict[PipelineStage, PipelineResult]:
        """BBPF: Execute pipeline with progressive validation and rollback"""
        
        print(f"🚀 BBPF: Starting progressive pipeline for '{self.project_name}'")
        
        for stage in PipelineStage:
            step = self.pipeline_steps[stage]
            
            # Check dependencies
            if not self._check_dependencies(step.dependencies):
                print(f"❌ BBPF: Dependencies not met for {stage.value}")
                return self.results
            
            # Execute step
            result = self._execute_step(step)
            self.results[stage] = result
            
            # Validate step output
            if result.status == PipelineStatus.SUCCESS:
                if not self._validate_step_output(step, result.output):
                    print(f"⚠️ BBPF: Validation failed for {stage.value}, rolling back...")
                    self._rollback_stage(stage)
                    return self.results
            
            # Check if we should continue
            if result.status == PipelineStatus.FAILED:
                print(f"❌ BBPF: Pipeline failed at {stage.value}")
                self._rollback_stage(stage)
                return self.results
            
            print(f"✅ BBPF: {stage.value} completed successfully")
        
        print(f"🎉 BBPF: Pipeline completed successfully!")
        return self.results
    
    def _check_dependencies(self, dependencies: List[PipelineStage]) -> bool:
        """BBPF: Check if all dependencies are satisfied"""
        
        for dep in dependencies:
            if dep not in self.results:
                return False
            if self.results[dep].status != PipelineStatus.SUCCESS:
                return False
        
        return True
    
    def _execute_step(self, step: PipelineStep) -> PipelineResult:
        """BBPF: Execute a single pipeline step"""
        
        print(f"🔄 BBPF: Executing {step.stage.value}...")
        
        try:
            # Prepare environment
            os.chdir(self.project_dir)
            
            # Execute command
            start_time = time.time()
            result = subprocess.run(
                step.command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=step.timeout
            )
            execution_time = time.time() - start_time
            
            if result.returncode == 0:
                return PipelineResult(
                    stage=step.stage,
                    status=PipelineStatus.SUCCESS,
                    output=result.stdout,
                    execution_time=execution_time
                )
            else:
                return PipelineResult(
                    stage=step.stage,
                    status=PipelineStatus.FAILED,
                    output=result.stdout,
                    error=result.stderr,
                    execution_time=execution_time
                )
                
        except subprocess.TimeoutExpired:
            return PipelineResult(
                stage=step.stage,
                status=PipelineStatus.FAILED,
                output="",
                error=f"Timeout after {step.timeout} seconds",
                execution_time=step.timeout
            )
        except Exception as e:
            return PipelineResult(
                stage=step.stage,
                status=PipelineStatus.FAILED,
                output="",
                error=str(e),
                execution_time=0.0
            )
    
    def _validate_step_output(self, step: PipelineStep, output: str) -> bool:
        """BBPF: Validate step output using custom validation functions"""
        
        if step.validation_check:
            validation_func = getattr(self, step.validation_check, None)
            if validation_func:
                return validation_func(output)
        
        # Default validation: check for error indicators
        error_indicators = ["error", "failed", "exception", "timeout"]
        return not any(indicator in output.lower() for indicator in error_indicators)
    
    def _rollback_stage(self, failed_stage: PipelineStage):
        """BBPF: Rollback to previous successful stage"""
        
        print(f"🔄 BBPF: Rolling back from {failed_stage.value}...")
        
        # Find previous successful stage
        previous_stage = None
        for stage in reversed(list(PipelineStage)):
            if stage == failed_stage:
                break
            if stage in self.results and self.results[stage].status == PipelineStatus.SUCCESS:
                previous_stage = stage
                break
        
        if previous_stage:
            step = self.pipeline_steps[previous_stage]
            if step.rollback_command:
                try:
                    subprocess.run(step.rollback_command, shell=True, check=True)
                    print(f"✅ BBPF: Rollback to {previous_stage.value} successful")
                except subprocess.CalledProcessError:
                    print(f"❌ BBPF: Rollback to {previous_stage.value} failed")
        else:
            print("❌ BBPF: No previous stage to rollback to")
    
    # Custom validation functions
    def validate_idea_structure(self, output: str) -> bool:
        """BBPF: Validate idea structure analysis"""
        return "is_valid: True" in output
    
    def check_analysis_output(self, output: str) -> bool:
        """BBPF: Check analysis output quality"""
        return len(output.strip()) > 100 and "architecture" in output.lower()
    
    def check_planning_output(self, output: str) -> bool:
        """BBPF: Check planning output quality"""
        return "plan" in output.lower() or "steps" in output.lower()
    
    def check_implementation_output(self, output: str) -> bool:
        """BBPF: Check implementation output quality"""
        return "created" in output.lower() or "generated" in output.lower()
    
    def check_testing_output(self, output: str) -> bool:
        """BBPF: Check testing output quality"""
        return "passed" in output.lower() or "success" in output.lower()
    
    def check_deployment_output(self, output: str) -> bool:
        """BBPF: Check deployment output quality"""
        return "deployed" in output.lower() or "running" in output.lower()

def progressive_claude_flow_pipeline(project_name: str, idea_text: str) -> Dict[PipelineStage, PipelineResult]:
    """BBPF: Main function for progressive Claude Flow pipeline"""
    
    pipeline = BBPFPipeline(project_name, idea_text)
    return pipeline.execute_pipeline()

# Example usage
if __name__ == "__main__":
    import time
    
    test_idea = """
    Build a simple task manager API.
    Users: Individual professionals
    Goal: Help users organize tasks
    Inputs: Task data
    Outputs: Task management API
    Runtime: Local development
    """
    
    results = progressive_claude_flow_pipeline("test_task_manager", test_idea)
    
    for stage, result in results.items():
        print(f"{stage.value}: {result.status.value}")
        if result.error:
            print(f"  Error: {result.error}")
