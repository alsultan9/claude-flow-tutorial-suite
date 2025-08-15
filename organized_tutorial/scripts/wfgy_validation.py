#!/usr/bin/env python3
"""
WFGY BBMC: Data Consistency Validation for Claude Flow Orchestration
Ensures input assumptions align with implementation requirements before processing.
"""

import re
import json
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum

class ValidationError(Exception):
    """BBMC Validation Error"""
    pass

class IdeaComplexity(Enum):
    SIMPLE = "simple"
    MEDIUM = "medium"
    COMPLEX = "complex"

@dataclass
class IdeaValidationResult:
    is_valid: bool
    complexity: IdeaComplexity
    missing_elements: List[str]
    recommendations: List[str]
    estimated_agents: int
    suggested_sparc_mode: str
    suggested_topology: str

class BBMCValidator:
    """BBMC: Validates idea consistency before Claude Flow orchestration"""
    
    def __init__(self):
        self.required_elements = {
            "users": r"users?|audience|target|who",
            "goal": r"goal|objective|purpose|problem|solve",
            "inputs": r"input|data|source|feed",
            "outputs": r"output|produce|result|deliver",
            "runtime": r"runtime|deploy|environment|local|cloud"
        }
        
        self.sparc_mode_keywords = {
            "architect": ["architecture", "system design", "microservices", "distributed", "scalable"],
            "api": ["api", "backend", "service", "rest", "endpoint"],
            "ui": ["frontend", "interface", "web", "mobile", "dashboard"],
            "ml": ["machine learning", "ai", "prediction", "model", "data science"],
            "tdd": ["test", "testing", "quality", "tdd", "bdd"],
            "devops": ["deploy", "ci/cd", "docker", "kubernetes", "infrastructure"]
        }
    
    def validate_idea_structure(self, idea_text: str) -> IdeaValidationResult:
        """BBMC: Validate idea has required structural elements"""
        
        idea_lower = idea_text.lower()
        missing_elements = []
        found_elements = []
        
        # Check for required elements
        for element, pattern in self.required_elements.items():
            if not re.search(pattern, idea_lower):
                missing_elements.append(element)
            else:
                found_elements.append(element)
        
        # Determine complexity based on content
        complexity = self._assess_complexity(idea_text)
        
        # Determine optimal SPARC mode
        suggested_sparc_mode = self._suggest_sparc_mode(idea_text)
        
        # Determine topology and agent count
        suggested_topology, estimated_agents = self._suggest_topology(complexity, idea_text)
        
        # Generate recommendations
        recommendations = self._generate_recommendations(missing_elements, complexity)
        
        # Validation passes if at least 3 core elements are present
        is_valid = len(found_elements) >= 3
        
        return IdeaValidationResult(
            is_valid=is_valid,
            complexity=complexity,
            missing_elements=missing_elements,
            recommendations=recommendations,
            estimated_agents=estimated_agents,
            suggested_sparc_mode=suggested_sparc_mode,
            suggested_topology=suggested_topology
        )
    
    def _assess_complexity(self, idea_text: str) -> IdeaComplexity:
        """BBMC: Assess idea complexity for resource allocation"""
        
        complexity_indicators = {
            "simple": [
                "simple", "basic", "single", "one", "individual", "personal",
                "task", "todo", "list", "note", "calculator"
            ],
            "complex": [
                "comprehensive", "enterprise", "distributed", "microservices",
                "real-time", "machine learning", "ai", "analytics", "dashboard",
                "multi-user", "scalable", "high-performance", "production"
            ]
        }
        
        idea_lower = idea_text.lower()
        
        simple_score = sum(1 for word in complexity_indicators["simple"] if word in idea_lower)
        complex_score = sum(1 for word in complexity_indicators["complex"] if word in idea_lower)
        
        if complex_score >= 3:
            return IdeaComplexity.COMPLEX
        elif simple_score >= 2:
            return IdeaComplexity.SIMPLE
        else:
            return IdeaComplexity.MEDIUM
    
    def _suggest_sparc_mode(self, idea_text: str) -> str:
        """BBMC: Suggest optimal SPARC mode based on content"""
        
        idea_lower = idea_text.lower()
        mode_scores = {}
        
        for mode, keywords in self.sparc_mode_keywords.items():
            score = sum(1 for keyword in keywords if keyword in idea_lower)
            mode_scores[mode] = score
        
        # Return mode with highest score, default to architect for complex projects
        best_mode = max(mode_scores, key=mode_scores.get)
        
        if mode_scores[best_mode] == 0:
            return "architect"  # Default for unclear requirements
        
        return best_mode
    
    def _suggest_topology(self, complexity: IdeaComplexity, idea_text: str) -> Tuple[str, int]:
        """BBMC: Suggest optimal topology and agent count"""
        
        idea_lower = idea_text.lower()
        
        # Determine if parallel processing is needed
        parallel_indicators = [
            "microservices", "distributed", "real-time", "analytics",
            "dashboard", "multiple", "integration", "api"
        ]
        
        needs_parallel = any(indicator in idea_lower for indicator in parallel_indicators)
        
        if complexity == IdeaComplexity.COMPLEX or needs_parallel:
            return "swarm", 7
        elif complexity == IdeaComplexity.MEDIUM:
            return "swarm", 5
        else:
            return "hive", 3
    
    def _generate_recommendations(self, missing_elements: List[str], complexity: IdeaComplexity) -> List[str]:
        """BBMC: Generate improvement recommendations"""
        
        recommendations = []
        
        if "users" in missing_elements:
            recommendations.append("Specify target users/audience for better scope definition")
        
        if "goal" in missing_elements:
            recommendations.append("Define clear problem/goal to solve")
        
        if "inputs" in missing_elements:
            recommendations.append("Describe data sources and inputs needed")
        
        if "outputs" in missing_elements:
            recommendations.append("Specify expected outputs and deliverables")
        
        if "runtime" in missing_elements:
            recommendations.append("Mention deployment environment (local/cloud)")
        
        if complexity == IdeaComplexity.SIMPLE:
            recommendations.append("Consider adding more technical details for better implementation")
        
        if complexity == IdeaComplexity.COMPLEX:
            recommendations.append("Consider breaking down into smaller components for better manageability")
        
        return recommendations

def validate_claude_flow_input(idea_text: str) -> IdeaValidationResult:
    """BBMC: Main validation function for Claude Flow input"""
    
    validator = BBMCValidator()
    return validator.validate_idea_structure(idea_text)

# Example usage
if __name__ == "__main__":
    test_idea = """
    Build a task manager for individual users.
    Users: Individual professionals and students
    Goal: Help users organize tasks and track productivity
    Inputs: Task descriptions, due dates, priority levels
    Outputs: Task lists, progress tracking, productivity reports
    Runtime: Local development with optional cloud sync
    """
    
    result = validate_claude_flow_input(test_idea)
    print(f"Valid: {result.is_valid}")
    print(f"Complexity: {result.complexity.value}")
    print(f"SPARC Mode: {result.suggested_sparc_mode}")
    print(f"Topology: {result.suggested_topology}")
    print(f"Agents: {result.estimated_agents}")
    print(f"Missing: {result.missing_elements}")
    print(f"Recommendations: {result.recommendations}")
