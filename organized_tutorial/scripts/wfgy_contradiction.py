#!/usr/bin/env python3
"""
WFGY BBCR: Contradiction Resolution for Claude Flow Orchestration
Detects when orchestration outputs contradict expected behavior and rollback.
"""

import re
import json
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from enum import Enum

class ContradictionType(Enum):
    ARCHITECTURE_MISMATCH = "architecture_mismatch"
    TECHNOLOGY_CONFLICT = "technology_conflict"
    REQUIREMENT_VIOLATION = "requirement_violation"
    PERFORMANCE_ISSUE = "performance_issue"
    SECURITY_VIOLATION = "security_violation"
    SCALABILITY_PROBLEM = "scalability_problem"

class ContradictionSeverity(Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

@dataclass
class Contradiction:
    type: ContradictionType
    severity: ContradictionSeverity
    description: str
    detected_in: str
    expected: str
    actual: str
    rollback_action: str

class BBCRDetector:
    """BBCR: Detects contradictions in Claude Flow orchestration outputs"""
    
    def __init__(self):
        self.contradiction_patterns = self._define_contradiction_patterns()
        self.technology_compatibility = self._define_technology_compatibility()
        self.architecture_constraints = self._define_architecture_constraints()
    
    def _define_contradiction_patterns(self) -> Dict[ContradictionType, List[Dict]]:
        """BBCR: Define patterns for detecting contradictions"""
        
        return {
            ContradictionType.ARCHITECTURE_MISMATCH: [
                {
                    "pattern": r"microservices.*monolith|monolith.*microservices",
                    "description": "Architecture style mismatch"
                },
                {
                    "pattern": r"serverless.*stateful|stateful.*serverless",
                    "description": "State management contradiction"
                }
            ],
            
            ContradictionType.TECHNOLOGY_CONFLICT: [
                {
                    "pattern": r"python.*node\.js.*same.*service",
                    "description": "Multiple languages in single service"
                },
                {
                    "pattern": r"sql.*nosql.*same.*data",
                    "description": "Database type conflict"
                }
            ],
            
            ContradictionType.REQUIREMENT_VIOLATION: [
                {
                    "pattern": r"real-time.*batch.*processing",
                    "description": "Processing mode contradiction"
                },
                {
                    "pattern": r"high-availability.*single.*point.*failure",
                    "description": "Availability requirement violation"
                }
            ],
            
            ContradictionType.PERFORMANCE_ISSUE: [
                {
                    "pattern": r"high-performance.*interpreted.*language",
                    "description": "Performance expectation mismatch"
                },
                {
                    "pattern": r"low-latency.*network.*call",
                    "description": "Latency expectation contradiction"
                }
            ],
            
            ContradictionType.SECURITY_VIOLATION: [
                {
                    "pattern": r"secure.*plain.*text.*password",
                    "description": "Security practice violation"
                },
                {
                    "pattern": r"authentication.*no.*auth",
                    "description": "Authentication requirement violation"
                }
            ],
            
            ContradictionType.SCALABILITY_PROBLEM: [
                {
                    "pattern": r"scalable.*single.*server",
                    "description": "Scalability architecture contradiction"
                },
                {
                    "pattern": r"distributed.*centralized.*database",
                    "description": "Distribution contradiction"
                }
            ]
        }
    
    def _define_technology_compatibility(self) -> Dict[str, List[str]]:
        """BBCR: Define technology compatibility matrix"""
        
        return {
            "python": ["fastapi", "django", "flask", "postgresql", "redis"],
            "nodejs": ["express", "nestjs", "mongodb", "redis", "postgresql"],
            "react": ["typescript", "javascript", "nodejs", "express"],
            "microservices": ["docker", "kubernetes", "api-gateway", "service-mesh"],
            "serverless": ["aws-lambda", "azure-functions", "stateless", "event-driven"],
            "real-time": ["websockets", "server-sent-events", "polling"],
            "high-performance": ["golang", "rust", "c++", "compiled-languages"]
        }
    
    def _define_architecture_constraints(self) -> Dict[str, List[str]]:
        """BBCR: Define architecture constraints"""
        
        return {
            "microservices": ["distributed", "api-gateway", "service-discovery"],
            "monolith": ["single-deployment", "shared-database"],
            "serverless": ["stateless", "event-driven", "auto-scaling"],
            "real-time": ["websockets", "low-latency", "persistent-connections"],
            "high-availability": ["redundancy", "load-balancing", "failover"]
        }
    
    def detect_contradictions(self, idea_text: str, implementation_output: str) -> List[Contradiction]:
        """BBCR: Detect contradictions between idea and implementation"""
        
        contradictions = []
        
        # Check for pattern-based contradictions
        for contradiction_type, patterns in self.contradiction_patterns.items():
            for pattern_info in patterns:
                if re.search(pattern_info["pattern"], implementation_output, re.IGNORECASE):
                    contradiction = Contradiction(
                        type=contradiction_type,
                        severity=self._assess_severity(contradiction_type),
                        description=pattern_info["description"],
                        detected_in="implementation_output",
                        expected="Consistent architecture and technology choices",
                        actual=f"Found: {pattern_info['pattern']}",
                        rollback_action=self._get_rollback_action(contradiction_type)
                    )
                    contradictions.append(contradiction)
        
        # Check technology compatibility
        tech_contradictions = self._check_technology_compatibility(idea_text, implementation_output)
        contradictions.extend(tech_contradictions)
        
        # Check architecture constraints
        arch_contradictions = self._check_architecture_constraints(idea_text, implementation_output)
        contradictions.extend(arch_contradictions)
        
        return contradictions
    
    def _assess_severity(self, contradiction_type: ContradictionType) -> ContradictionSeverity:
        """BBCR: Assess severity of contradiction type"""
        
        severity_map = {
            ContradictionType.ARCHITECTURE_MISMATCH: ContradictionSeverity.HIGH,
            ContradictionType.TECHNOLOGY_CONFLICT: ContradictionSeverity.MEDIUM,
            ContradictionType.REQUIREMENT_VIOLATION: ContradictionSeverity.CRITICAL,
            ContradictionType.PERFORMANCE_ISSUE: ContradictionSeverity.HIGH,
            ContradictionType.SECURITY_VIOLATION: ContradictionSeverity.CRITICAL,
            ContradictionType.SCALABILITY_PROBLEM: ContradictionSeverity.HIGH
        }
        
        return severity_map.get(contradiction_type, ContradictionSeverity.MEDIUM)
    
    def _check_technology_compatibility(self, idea_text: str, implementation_output: str) -> List[Contradiction]:
        """BBCR: Check for technology compatibility issues"""
        
        contradictions = []
        
        # Extract mentioned technologies
        idea_tech = self._extract_technologies(idea_text)
        impl_tech = self._extract_technologies(implementation_output)
        
        # Check for incompatible combinations
        for tech1 in idea_tech:
            for tech2 in impl_tech:
                if tech1 != tech2 and not self._are_compatible(tech1, tech2):
                    contradiction = Contradiction(
                        type=ContradictionType.TECHNOLOGY_CONFLICT,
                        severity=ContradictionSeverity.MEDIUM,
                        description=f"Incompatible technologies: {tech1} and {tech2}",
                        detected_in="technology_analysis",
                        expected=f"Compatible technology stack with {tech1}",
                        actual=f"Found incompatible {tech2}",
                        rollback_action="Review and align technology choices"
                    )
                    contradictions.append(contradiction)
        
        return contradictions
    
    def _check_architecture_constraints(self, idea_text: str, implementation_output: str) -> List[Contradiction]:
        """BBCR: Check for architecture constraint violations"""
        
        contradictions = []
        
        # Extract architecture requirements
        idea_arch = self._extract_architecture_requirements(idea_text)
        impl_arch = self._extract_architecture_requirements(implementation_output)
        
        # Check for missing required components
        for arch_req in idea_arch:
            if arch_req not in impl_arch:
                required_components = self.architecture_constraints.get(arch_req, [])
                missing_components = [comp for comp in required_components if comp not in impl_arch]
                
                if missing_components:
                    contradiction = Contradiction(
                        type=ContradictionType.ARCHITECTURE_MISMATCH,
                        severity=ContradictionSeverity.HIGH,
                        description=f"Missing architecture components for {arch_req}",
                        detected_in="architecture_analysis",
                        expected=f"Architecture {arch_req} with components: {required_components}",
                        actual=f"Missing: {missing_components}",
                        rollback_action="Add missing architecture components"
                    )
                    contradictions.append(contradiction)
        
        return contradictions
    
    def _extract_technologies(self, text: str) -> List[str]:
        """BBCR: Extract mentioned technologies from text"""
        
        tech_keywords = [
            "python", "nodejs", "react", "angular", "vue", "java", "golang", "rust",
            "postgresql", "mongodb", "redis", "mysql", "sqlite",
            "docker", "kubernetes", "aws", "azure", "gcp",
            "express", "fastapi", "django", "flask", "spring"
        ]
        
        found_tech = []
        text_lower = text.lower()
        
        for tech in tech_keywords:
            if tech in text_lower:
                found_tech.append(tech)
        
        return found_tech
    
    def _extract_architecture_requirements(self, text: str) -> List[str]:
        """BBCR: Extract architecture requirements from text"""
        
        arch_keywords = [
            "microservices", "monolith", "serverless", "real-time",
            "high-availability", "scalable", "distributed", "centralized"
        ]
        
        found_arch = []
        text_lower = text.lower()
        
        for arch in arch_keywords:
            if arch in text_lower:
                found_arch.append(arch)
        
        return found_arch
    
    def _are_compatible(self, tech1: str, tech2: str) -> bool:
        """BBCR: Check if two technologies are compatible"""
        
        for tech, compatible_list in self.technology_compatibility.items():
            if tech1 == tech and tech2 in compatible_list:
                return True
            if tech2 == tech and tech1 in compatible_list:
                return True
        
        return False
    
    def _get_rollback_action(self, contradiction_type: ContradictionType) -> str:
        """BBCR: Get appropriate rollback action for contradiction type"""
        
        rollback_actions = {
            ContradictionType.ARCHITECTURE_MISMATCH: "Rollback to previous architecture decision",
            ContradictionType.TECHNOLOGY_CONFLICT: "Review and align technology stack",
            ContradictionType.REQUIREMENT_VIOLATION: "Rollback to requirement validation stage",
            ContradictionType.PERFORMANCE_ISSUE: "Optimize or change technology choice",
            ContradictionType.SECURITY_VIOLATION: "Rollback to security review stage",
            ContradictionType.SCALABILITY_PROBLEM: "Reconsider architecture for scalability"
        }
        
        return rollback_actions.get(contradiction_type, "Review and fix contradiction")

class BBCRResolver:
    """BBCR: Resolves contradictions and provides corrective actions"""
    
    def __init__(self, detector: BBCRDetector):
        self.detector = detector
    
    def resolve_contradictions(self, idea_text: str, implementation_output: str) -> Dict[str, Any]:
        """BBCR: Resolve contradictions and provide corrective actions"""
        
        # Detect contradictions
        contradictions = self.detector.detect_contradictions(idea_text, implementation_output)
        
        # Analyze severity distribution
        severity_counts = self._count_severity_levels(contradictions)
        
        # Determine if rollback is needed
        needs_rollback = self._needs_rollback(contradictions)
        
        # Generate corrective actions
        corrective_actions = self._generate_corrective_actions(contradictions)
        
        return {
            "contradictions_found": len(contradictions),
            "severity_distribution": severity_counts,
            "needs_rollback": needs_rollback,
            "contradictions": contradictions,
            "corrective_actions": corrective_actions,
            "can_proceed": not needs_rollback
        }
    
    def _count_severity_levels(self, contradictions: List[Contradiction]) -> Dict[str, int]:
        """BBCR: Count contradictions by severity level"""
        
        counts = {"low": 0, "medium": 0, "high": 0, "critical": 0}
        
        for contradiction in contradictions:
            severity = contradiction.severity.value
            counts[severity] += 1
        
        return counts
    
    def _needs_rollback(self, contradictions: List[Contradiction]) -> bool:
        """BBCR: Determine if rollback is needed based on contradictions"""
        
        # Rollback if any critical contradictions
        critical_contradictions = [c for c in contradictions if c.severity == ContradictionSeverity.CRITICAL]
        if critical_contradictions:
            return True
        
        # Rollback if too many high-severity contradictions
        high_contradictions = [c for c in contradictions if c.severity == ContradictionSeverity.HIGH]
        if len(high_contradictions) >= 2:
            return True
        
        return False
    
    def _generate_corrective_actions(self, contradictions: List[Contradiction]) -> List[str]:
        """BBCR: Generate corrective actions for contradictions"""
        
        actions = []
        
        for contradiction in contradictions:
            if contradiction.severity in [ContradictionSeverity.CRITICAL, ContradictionSeverity.HIGH]:
                actions.append(f"CRITICAL: {contradiction.rollback_action}")
            else:
                actions.append(f"WARNING: {contradiction.rollback_action}")
        
        return actions

def bbcr_validate_claude_flow_output(idea_text: str, implementation_output: str) -> Dict[str, Any]:
    """BBCR: Main function for contradiction detection and resolution"""
    
    detector = BBCRDetector()
    resolver = BBCRResolver(detector)
    
    return resolver.resolve_contradictions(idea_text, implementation_output)

# Example usage
if __name__ == "__main__":
    test_idea = """
    Build a high-performance real-time analytics platform.
    Users: Data analysts and business users
    Goal: Provide real-time insights with sub-second latency
    Inputs: Streaming data from multiple sources
    Outputs: Real-time dashboards and alerts
    Runtime: Cloud deployment with auto-scaling
    """
    
    test_implementation = """
    Created a Python-based analytics platform using Django and SQLite.
    The system uses batch processing for data analysis.
    Single server deployment for simplicity.
    """
    
    result = bbcr_validate_claude_flow_output(test_idea, test_implementation)
    
    print(f"Contradictions found: {result['contradictions_found']}")
    print(f"Needs rollback: {result['needs_rollback']}")
    print(f"Can proceed: {result['can_proceed']}")
    
    for contradiction in result['contradictions']:
        print(f"\n{contradiction.severity.value.upper()}: {contradiction.description}")
        print(f"Action: {contradiction.rollback_action}")
