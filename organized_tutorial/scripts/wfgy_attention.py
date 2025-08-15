#!/usr/bin/env python3
"""
WFGY BBAM: Attention Management for Claude Flow Orchestration
Focuses computational resources on variables and transformations most affecting orchestration performance.
"""

import re
import json
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from enum import Enum

class AttentionPriority(Enum):
    CRITICAL = "critical"      # Highest impact on success
    HIGH = "high"             # Significant impact
    MEDIUM = "medium"         # Moderate impact
    LOW = "low"              # Minimal impact

class ResourceType(Enum):
    AGENTS = "agents"
    TIME = "time"
    MEMORY = "memory"
    COMPLEXITY = "complexity"

@dataclass
class AttentionTarget:
    name: str
    priority: AttentionPriority
    resource_type: ResourceType
    impact_score: float
    description: str
    optimization_strategy: str

class BBAMManager:
    """BBAM: Manages attention and resource allocation for Claude Flow orchestration"""
    
    def __init__(self):
        self.attention_targets = self._define_attention_targets()
        self.resource_limits = self._define_resource_limits()
        self.optimization_strategies = self._define_optimization_strategies()
    
    def _define_attention_targets(self) -> Dict[str, AttentionTarget]:
        """BBAM: Define critical attention targets for orchestration success"""
        
        return {
            # CRITICAL: Direct impact on orchestration success
            "idea_clarity": AttentionTarget(
                name="idea_clarity",
                priority=AttentionPriority.CRITICAL,
                resource_type=ResourceType.AGENTS,
                impact_score=0.95,
                description="Clarity and completeness of user idea",
                optimization_strategy="Validate idea structure before orchestration"
            ),
            
            "sparc_mode_selection": AttentionTarget(
                name="sparc_mode_selection",
                priority=AttentionPriority.CRITICAL,
                resource_type=ResourceType.AGENTS,
                impact_score=0.90,
                description="Optimal SPARC mode for project type",
                optimization_strategy="Analyze idea content for mode selection"
            ),
            
            "topology_optimization": AttentionTarget(
                name="topology_optimization",
                priority=AttentionPriority.CRITICAL,
                resource_type=ResourceType.AGENTS,
                impact_score=0.85,
                description="Optimal agent topology and count",
                optimization_strategy="Match topology to project complexity"
            ),
            
            # HIGH: Significant impact on performance
            "agent_coordination": AttentionTarget(
                name="agent_coordination",
                priority=AttentionPriority.HIGH,
                resource_type=ResourceType.TIME,
                impact_score=0.75,
                description="Efficient agent communication and coordination",
                optimization_strategy="Optimize communication patterns"
            ),
            
            "memory_management": AttentionTarget(
                name="memory_management",
                priority=AttentionPriority.HIGH,
                resource_type=ResourceType.MEMORY,
                impact_score=0.70,
                description="Efficient memory usage across agents",
                optimization_strategy="Implement memory sharing and cleanup"
            ),
            
            "error_handling": AttentionTarget(
                name="error_handling",
                priority=AttentionPriority.HIGH,
                resource_type=ResourceType.COMPLEXITY,
                impact_score=0.65,
                description="Robust error detection and recovery",
                optimization_strategy="Implement comprehensive error handling"
            ),
            
            # MEDIUM: Moderate impact
            "progress_tracking": AttentionTarget(
                name="progress_tracking",
                priority=AttentionPriority.MEDIUM,
                resource_type=ResourceType.TIME,
                impact_score=0.50,
                description="Real-time progress monitoring",
                optimization_strategy="Implement progress indicators"
            ),
            
            "resource_monitoring": AttentionTarget(
                name="resource_monitoring",
                priority=AttentionPriority.MEDIUM,
                resource_type=ResourceType.MEMORY,
                impact_score=0.45,
                description="System resource usage monitoring",
                optimization_strategy="Monitor CPU, memory, and network usage"
            ),
            
            # LOW: Minimal impact
            "logging": AttentionTarget(
                name="logging",
                priority=AttentionPriority.LOW,
                resource_type=ResourceType.MEMORY,
                impact_score=0.25,
                description="Detailed logging and debugging",
                optimization_strategy="Implement structured logging"
            ),
            
            "documentation": AttentionTarget(
                name="documentation",
                priority=AttentionPriority.LOW,
                resource_type=ResourceType.TIME,
                impact_score=0.20,
                description="Real-time documentation generation",
                optimization_strategy="Generate documentation as needed"
            )
        }
    
    def _define_resource_limits(self) -> Dict[ResourceType, Dict[str, Any]]:
        """BBAM: Define resource limits and constraints"""
        
        return {
            ResourceType.AGENTS: {
                "max_agents": 8,
                "min_agents": 3,
                "optimal_range": (5, 7),
                "cost_per_agent": 1.0
            },
            ResourceType.TIME: {
                "max_execution_time": 1800,  # 30 minutes
                "timeout_threshold": 1500,   # 25 minutes
                "optimal_duration": 900      # 15 minutes
            },
            ResourceType.MEMORY: {
                "max_memory_per_agent": 512,  # MB
                "total_memory_limit": 4096,   # MB
                "memory_warning_threshold": 3072  # MB
            },
            ResourceType.COMPLEXITY: {
                "max_complexity_score": 10,
                "complexity_threshold": 7,
                "simplification_target": 5
            }
        }
    
    def _define_optimization_strategies(self) -> Dict[str, List[str]]:
        """BBAM: Define optimization strategies for each attention target"""
        
        return {
            "idea_clarity": [
                "Validate idea structure before processing",
                "Request clarification for missing elements",
                "Suggest improvements for better implementation"
            ],
            "sparc_mode_selection": [
                "Analyze idea content for optimal mode",
                "Consider project complexity and requirements",
                "Match mode to project characteristics"
            ],
            "topology_optimization": [
                "Use swarm for complex, parallel tasks",
                "Use hive-mind for focused, sequential tasks",
                "Optimize agent count based on complexity"
            ],
            "agent_coordination": [
                "Implement efficient communication patterns",
                "Reduce inter-agent dependencies",
                "Optimize task distribution"
            ],
            "memory_management": [
                "Implement memory sharing between agents",
                "Clean up unused resources",
                "Monitor memory usage patterns"
            ],
            "error_handling": [
                "Implement comprehensive error detection",
                "Provide clear error messages",
                "Enable automatic recovery where possible"
            ]
        }
    
    def analyze_attention_requirements(self, idea_text: str, project_complexity: str) -> Dict[str, Any]:
        """BBAM: Analyze attention requirements for orchestration"""
        
        # Analyze idea clarity
        clarity_score = self._analyze_idea_clarity(idea_text)
        
        # Determine optimal SPARC mode
        optimal_sparc_mode = self._determine_optimal_sparc_mode(idea_text)
        
        # Determine optimal topology
        optimal_topology = self._determine_optimal_topology(project_complexity, idea_text)
        
        # Calculate resource requirements
        resource_requirements = self._calculate_resource_requirements(
            clarity_score, optimal_topology, project_complexity
        )
        
        # Generate optimization recommendations
        optimizations = self._generate_optimization_recommendations(
            clarity_score, optimal_sparc_mode, optimal_topology
        )
        
        return {
            "clarity_score": clarity_score,
            "optimal_sparc_mode": optimal_sparc_mode,
            "optimal_topology": optimal_topology,
            "resource_requirements": resource_requirements,
            "optimization_recommendations": optimizations,
            "attention_priorities": self._get_attention_priorities(clarity_score, project_complexity)
        }
    
    def _analyze_idea_clarity(self, idea_text: str) -> float:
        """BBAM: Analyze clarity and completeness of idea"""
        
        clarity_indicators = {
            "users": r"users?|audience|target|who",
            "goal": r"goal|objective|purpose|problem|solve",
            "inputs": r"input|data|source|feed",
            "outputs": r"output|produce|result|deliver",
            "runtime": r"runtime|deploy|environment|local|cloud",
            "technical_details": r"api|database|framework|language|architecture"
        }
        
        idea_lower = idea_text.lower()
        found_elements = 0
        total_elements = len(clarity_indicators)
        
        for element, pattern in clarity_indicators.items():
            if re.search(pattern, idea_lower):
                found_elements += 1
        
        # Calculate clarity score (0-1)
        base_score = found_elements / total_elements
        
        # Bonus for technical details
        technical_bonus = 0.1 if re.search(r"technical|architecture|framework", idea_lower) else 0
        
        # Penalty for vagueness
        vagueness_penalty = 0.1 if re.search(r"something|anything|whatever", idea_lower) else 0
        
        return min(1.0, max(0.0, base_score + technical_bonus - vagueness_penalty))
    
    def _determine_optimal_sparc_mode(self, idea_text: str) -> str:
        """BBAM: Determine optimal SPARC mode based on idea content"""
        
        mode_keywords = {
            "architect": ["architecture", "system design", "microservices", "distributed", "scalable"],
            "api": ["api", "backend", "service", "rest", "endpoint"],
            "ui": ["frontend", "interface", "web", "mobile", "dashboard"],
            "ml": ["machine learning", "ai", "prediction", "model", "data science"],
            "tdd": ["test", "testing", "quality", "tdd", "bdd"],
            "devops": ["deploy", "ci/cd", "docker", "kubernetes", "infrastructure"]
        }
        
        idea_lower = idea_text.lower()
        mode_scores = {}
        
        for mode, keywords in mode_keywords.items():
            score = sum(1 for keyword in keywords if keyword in idea_lower)
            mode_scores[mode] = score
        
        # Return mode with highest score, default to architect
        best_mode = max(mode_scores, key=mode_scores.get)
        return best_mode if mode_scores[best_mode] > 0 else "architect"
    
    def _determine_optimal_topology(self, complexity: str, idea_text: str) -> Dict[str, Any]:
        """BBAM: Determine optimal topology and agent count"""
        
        complexity_scores = {"simple": 1, "medium": 2, "complex": 3}
        complexity_score = complexity_scores.get(complexity.lower(), 2)
        
        # Analyze idea for parallel processing needs
        parallel_indicators = [
            "microservices", "distributed", "real-time", "analytics",
            "dashboard", "multiple", "integration", "api"
        ]
        
        idea_lower = idea_text.lower()
        parallel_score = sum(1 for indicator in parallel_indicators if indicator in idea_lower)
        
        # Determine topology
        if complexity_score >= 3 or parallel_score >= 2:
            topology = "swarm"
            agent_count = min(8, 5 + complexity_score)
        elif complexity_score >= 2:
            topology = "swarm"
            agent_count = 5
        else:
            topology = "hive"
            agent_count = 3
        
        return {
            "topology": topology,
            "agent_count": int(agent_count),
            "reasoning": f"Complexity: {complexity_score}, Parallel indicators: {parallel_score}"
        }
    
    def _calculate_resource_requirements(self, clarity_score: float, topology: Dict, complexity: str) -> Dict[str, Any]:
        """BBAM: Calculate resource requirements"""
        
        agent_count = topology["agent_count"]
        
        # Calculate time requirements
        base_time = 300  # 5 minutes base
        complexity_multiplier = {"simple": 1.0, "medium": 1.5, "complex": 2.5}
        time_multiplier = complexity_multiplier.get(complexity.lower(), 1.5)
        
        estimated_time = base_time * time_multiplier * (1 + (1 - clarity_score))
        
        # Calculate memory requirements
        memory_per_agent = self.resource_limits[ResourceType.MEMORY]["max_memory_per_agent"]
        total_memory = agent_count * memory_per_agent
        
        # Calculate complexity score
        complexity_score = min(10, agent_count * 1.5 + (1 - clarity_score) * 3)
        
        return {
            "estimated_time_seconds": int(estimated_time),
            "memory_requirements_mb": total_memory,
            "complexity_score": complexity_score,
            "agent_count": agent_count
        }
    
    def _generate_optimization_recommendations(self, clarity_score: float, sparc_mode: str, topology: Dict) -> List[str]:
        """BBAM: Generate optimization recommendations"""
        
        recommendations = []
        
        # Clarity-based recommendations
        if clarity_score < 0.6:
            recommendations.append("Request clarification for missing project elements")
            recommendations.append("Suggest specific technical requirements")
        
        # SPARC mode recommendations
        if sparc_mode == "architect":
            recommendations.append("Focus on system architecture and design patterns")
        elif sparc_mode == "api":
            recommendations.append("Prioritize API design and backend implementation")
        elif sparc_mode == "ui":
            recommendations.append("Focus on user interface and frontend development")
        
        # Topology recommendations
        if topology["topology"] == "swarm":
            recommendations.append("Optimize for parallel processing and agent coordination")
        else:
            recommendations.append("Focus on sequential task execution and agent efficiency")
        
        return recommendations
    
    def _get_attention_priorities(self, clarity_score: float, complexity: str) -> List[AttentionTarget]:
        """BBAM: Get prioritized attention targets"""
        
        # Get all attention targets
        all_targets = list(self.attention_targets.values())
        
        # Adjust priorities based on clarity and complexity
        for target in all_targets:
            if target.name == "idea_clarity" and clarity_score < 0.7:
                target.priority = AttentionPriority.CRITICAL
            elif target.name == "topology_optimization" and complexity.lower() == "complex":
                target.priority = AttentionPriority.CRITICAL
        
        # Sort by priority and impact score
        sorted_targets = sorted(
            all_targets,
            key=lambda x: (x.priority.value, x.impact_score),
            reverse=True
        )
        
        return sorted_targets[:5]  # Return top 5 priorities

class BBAMOptimizer:
    """BBAM: Optimizes resource allocation based on attention analysis"""
    
    def __init__(self, manager: BBAMManager):
        self.manager = manager
    
    def optimize_orchestration(self, idea_text: str, project_complexity: str) -> Dict[str, Any]:
        """BBAM: Optimize orchestration parameters"""
        
        # Analyze attention requirements
        analysis = self.manager.analyze_attention_requirements(idea_text, project_complexity)
        
        # Generate optimized parameters
        optimized_params = self._generate_optimized_parameters(analysis)
        
        # Create execution plan
        execution_plan = self._create_execution_plan(analysis, optimized_params)
        
        return {
            "analysis": analysis,
            "optimized_parameters": optimized_params,
            "execution_plan": execution_plan,
            "resource_allocation": self._allocate_resources(analysis)
        }
    
    def _generate_optimized_parameters(self, analysis: Dict[str, Any]) -> Dict[str, Any]:
        """BBAM: Generate optimized orchestration parameters"""
        
        return {
            "sparc_mode": analysis["optimal_sparc_mode"],
            "topology": analysis["optimal_topology"]["topology"],
            "agent_count": analysis["optimal_topology"]["agent_count"],
            "timeout_seconds": analysis["resource_requirements"]["estimated_time_seconds"],
            "memory_limit_mb": analysis["resource_requirements"]["memory_requirements_mb"],
            "complexity_threshold": analysis["resource_requirements"]["complexity_score"]
        }
    
    def _create_execution_plan(self, analysis: Dict[str, Any], params: Dict[str, Any]) -> List[Dict[str, Any]]:
        """BBAM: Create optimized execution plan"""
        
        plan = []
        
        # Phase 1: Validation and Analysis
        plan.append({
            "phase": "validation",
            "description": "Validate idea clarity and structure",
            "priority": "critical",
            "estimated_time": 60,
            "agents_required": 1
        })
        
        # Phase 2: Planning
        plan.append({
            "phase": "planning",
            "description": f"Create implementation plan using {params['sparc_mode']} mode",
            "priority": "critical",
            "estimated_time": 120,
            "agents_required": params["agent_count"]
        })
        
        # Phase 3: Implementation
        plan.append({
            "phase": "implementation",
            "description": f"Implement project using {params['topology']} topology",
            "priority": "high",
            "estimated_time": params["timeout_seconds"] - 180,
            "agents_required": params["agent_count"]
        })
        
        # Phase 4: Validation
        plan.append({
            "phase": "validation",
            "description": "Validate implementation and run tests",
            "priority": "high",
            "estimated_time": 120,
            "agents_required": 2
        })
        
        return plan
    
    def _allocate_resources(self, analysis: Dict[str, Any]) -> Dict[str, Any]:
        """BBAM: Allocate resources based on attention priorities"""
        
        priorities = analysis["attention_priorities"]
        requirements = analysis["resource_requirements"]
        
        allocation = {
            "agents": {
                "total": requirements["agent_count"],
                "critical_tasks": int(requirements["agent_count"] * 0.6),
                "high_priority_tasks": int(requirements["agent_count"] * 0.3),
                "monitoring_tasks": int(requirements["agent_count"] * 0.1)
            },
            "memory": {
                "total_mb": requirements["memory_requirements_mb"],
                "per_agent_mb": requirements["memory_requirements_mb"] // requirements["agent_count"],
                "reserve_mb": 512
            },
            "time": {
                "total_seconds": requirements["estimated_time_seconds"],
                "validation_phase": 60,
                "planning_phase": 120,
                "implementation_phase": requirements["estimated_time_seconds"] - 180,
                "testing_phase": 120
            }
        }
        
        return allocation

def bbam_optimize_claude_flow(idea_text: str, project_complexity: str = "medium") -> Dict[str, Any]:
    """BBAM: Main function for attention management and optimization"""
    
    manager = BBAMManager()
    optimizer = BBAMOptimizer(manager)
    
    return optimizer.optimize_orchestration(idea_text, project_complexity)

# Example usage
if __name__ == "__main__":
    test_idea = """
    Build a comprehensive e-commerce analytics platform.
    Users: Data analysts and business managers
    Goal: Provide real-time insights into customer behavior and sales performance
    Inputs: Customer transaction data, website analytics, inventory data
    Outputs: Real-time dashboards, predictive analytics, automated reports
    Runtime: Cloud deployment with auto-scaling and multi-region support
    """
    
    result = bbam_optimize_claude_flow(test_idea, "complex")
    
    print("BBAM Analysis Results:")
    print(f"Clarity Score: {result['analysis']['clarity_score']:.2f}")
    print(f"Optimal SPARC Mode: {result['analysis']['optimal_sparc_mode']}")
    print(f"Topology: {result['analysis']['optimal_topology']['topology']}")
    print(f"Agent Count: {result['analysis']['optimal_topology']['agent_count']}")
    
    print("\nOptimized Parameters:")
    for key, value in result['optimized_parameters'].items():
        print(f"  {key}: {value}")
    
    print("\nTop Attention Priorities:")
    for i, priority in enumerate(result['analysis']['attention_priorities'][:3], 1):
        print(f"  {i}. {priority.name} ({priority.priority.value}) - {priority.description}")
