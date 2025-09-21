#!/usr/bin/env python3
"""
Rails BDD Generator - Claude MCP Tool Python Wrapper

This provides a Python interface for the Rails BDD Generator tool,
making it easy to integrate with Claude's Model Context Protocol.
"""

import json
import subprocess
import os
from typing import Dict, Any, Optional, Union
from pathlib import Path


class RailsBddGenerator:
    """Python wrapper for the Rails BDD Generator Claude tool."""

    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize the Rails BDD Generator.

        Args:
            api_key: Optional Anthropic API key for AI features
        """
        self.api_key = api_key or os.environ.get('ANTHROPIC_API_KEY')
        self.tool_path = Path(__file__).parent / 'rails_bdd_tool.rb'

    def generate(
        self,
        description: Optional[str] = None,
        specification: Optional[Dict] = None,
        output_path: str = './generated_app',
        use_ai: bool = True
    ) -> Dict[str, Any]:
        """
        Generate a Rails application.

        Args:
            description: Natural language description of the app
            specification: Detailed spec with entities and relationships
            output_path: Where to generate the app
            use_ai: Whether to use AI for design (requires API key)

        Returns:
            Result dictionary with success status and details
        """
        if not description and not specification:
            return {
                'success': False,
                'error': 'Either description or specification is required'
            }

        params = {'output_path': output_path, 'use_ai': use_ai}

        if description:
            params['description'] = description
        else:
            params['specification'] = specification

        return self._run_tool('generate_rails_app', params)

    def design(self, description: str) -> Dict[str, Any]:
        """
        Design a Rails application architecture using AI.

        Args:
            description: Natural language description of the app

        Returns:
            Design specification with entities, relationships, etc.
        """
        if not self.api_key:
            return {
                'success': False,
                'error': 'ANTHROPIC_API_KEY is required for AI design'
            }

        return self._run_tool('design_rails_app', {'description': description})

    def _run_tool(self, tool_name: str, params: Dict) -> Dict[str, Any]:
        """Run the Ruby tool and return the result."""
        input_data = {
            'tool': tool_name,
            'params': params
        }

        env = os.environ.copy()
        if self.api_key:
            env['ANTHROPIC_API_KEY'] = self.api_key

        try:
            # Run the Ruby tool
            result = subprocess.run(
                ['ruby', str(self.tool_path), 'json'],
                input=json.dumps(input_data),
                capture_output=True,
                text=True,
                env=env
            )

            if result.returncode != 0:
                return {
                    'success': False,
                    'error': f'Tool failed: {result.stderr}'
                }

            return json.loads(result.stdout)

        except json.JSONDecodeError as e:
            return {
                'success': False,
                'error': f'Invalid JSON response: {e}'
            }
        except Exception as e:
            return {
                'success': False,
                'error': f'Tool execution failed: {e}'
            }


def handle_tool_call(tool_name: str, arguments: Dict) -> Dict[str, Any]:
    """
    MCP tool handler function.

    This is the main entry point for Claude to call the tool.

    Args:
        tool_name: Name of the tool to invoke
        arguments: Tool arguments

    Returns:
        Tool result
    """
    generator = RailsBddGenerator()

    if tool_name == 'generate_rails_app':
        return generator.generate(
            description=arguments.get('description'),
            specification=arguments.get('specification'),
            output_path=arguments.get('output_path', './generated_app'),
            use_ai=arguments.get('use_ai', True)
        )
    elif tool_name == 'design_rails_app':
        return generator.design(arguments['description'])
    else:
        return {
            'success': False,
            'error': f'Unknown tool: {tool_name}'
        }


# Example usage and testing
if __name__ == '__main__':
    import sys

    if len(sys.argv) < 2:
        print("Rails BDD Generator - Python Interface")
        print("======================================")
        print("")
        print("Usage: python rails_bdd_tool.py <command> [args]")
        print("")
        print("Commands:")
        print("  generate <description>  - Generate a Rails app")
        print("  design <description>    - Design architecture")
        print("  test                    - Run tests")
        sys.exit(1)

    command = sys.argv[1]
    generator = RailsBddGenerator()

    if command == 'generate':
        description = sys.argv[2] if len(sys.argv) > 2 else 'Sample app'
        result = generator.generate(description=description)
        print(json.dumps(result, indent=2))

    elif command == 'design':
        description = sys.argv[2] if len(sys.argv) > 2 else 'Sample app'
        result = generator.design(description)
        print(json.dumps(result, indent=2))

    elif command == 'test':
        print("Testing Rails BDD Generator...")

        # Test without AI
        result = generator.generate(
            description='Simple todo list',
            output_path='/tmp/test_todo_py',
            use_ai=False
        )

        if result['success']:
            print(f"✅ Test passed! Generated at: {result['app_path']}")
        else:
            print(f"❌ Test failed: {result['error']}")

    else:
        print(f"Unknown command: {command}")