#!/usr/bin/env python3
"""Script to check that solution files match user files with TODOs completed"""

import os
import re
from pathlib import Path

def remove_comments(content):
    """Remove single-line and multi-line comments from Solidity code"""
    # Remove single-line comments
    content = re.sub(r'//.*?$', '', content, flags=re.MULTILINE)
    # Remove multi-line comments
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    return content

def extract_declarations(file_path):
    """Extract function, event, struct declarations from a Solidity file"""
    if not file_path.exists():
        return {'functions': set(), 'events': set(), 'structs': set()}
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Remove comments to avoid false positives
    content = remove_comments(content)
    
    result = {
        'functions': set(),
        'events': set(),
        'structs': set()
    }
    
    # Extract functions - match function name and visibility (only actual declarations)
    # Look for function declarations that are not in comments
    func_pattern = r'^\s*function\s+(\w+)\s*\([^)]*\)\s*(public|external|internal|private)?'
    for match in re.finditer(func_pattern, content, re.MULTILINE):
        func_name = match.group(1)
        # Skip if it's a common false positive
        if func_name not in ['visibility', 'require', 'revert']:
            result['functions'].add(func_name)
    
    # Extract events - only actual declarations
    event_pattern = r'^\s*event\s+(\w+)\s*\([^)]*\)'
    for match in re.finditer(event_pattern, content, re.MULTILINE):
        event_name = match.group(1)
        # Skip if it's a common false positive
        if event_name not in ['data', 'revert']:
            result['events'].add(event_name)
    
    # Extract structs
    struct_pattern = r'^\s*struct\s+(\w+)\s*\{'
    for match in re.finditer(struct_pattern, content, re.MULTILINE):
        result['structs'].add(match.group(1))
    
    return result

def find_solution_file(user_file, solution_dir):
    """Find the corresponding solution file"""
    base_name = user_file.stem
    
    # Try common naming patterns
    patterns = [
        base_name + 'Solution.sol',
        base_name.replace('Solution', '') + 'Solution.sol',
        user_file.name.replace('.sol', 'Solution.sol')
    ]
    
    for pattern in patterns:
        sol_file = solution_dir / pattern
        if sol_file.exists():
            return sol_file
    
    return None

def main():
    foundry_dir = Path('foundry')
    if not foundry_dir.exists():
        print("Error: foundry directory not found")
        return
    
    issues = []
    
    # Iterate through all numbered project directories
    projects = sorted([d for d in foundry_dir.iterdir() 
                      if d.is_dir() and d.name[0].isdigit()])
    
    for project in projects:
        src_dir = project / 'src'
        if not src_dir.exists():
            continue
        
        solution_dir = src_dir / 'solution'
        if not solution_dir.exists():
            continue
        
        # Find user files (not solution files)
        user_files = [f for f in src_dir.glob('*.sol') 
                     if 'solution' not in str(f).lower()]
        
        for user_file in user_files:
            solution_file = find_solution_file(user_file, solution_dir)
            if not solution_file:
                continue
            
            user_decls = extract_declarations(user_file)
            sol_decls = extract_declarations(solution_file)
            
            # Check for missing declarations
            missing_events = user_decls['events'] - sol_decls['events']
            missing_funcs = user_decls['functions'] - sol_decls['functions']
            missing_structs = user_decls['structs'] - sol_decls['structs']
            
            if missing_events or missing_funcs or missing_structs:
                rel_path = user_file.relative_to(foundry_dir)
                issues.append({
                    'file': rel_path,
                    'missing_events': missing_events,
                    'missing_funcs': missing_funcs,
                    'missing_structs': missing_structs
                })
    
    # Report issues
    if issues:
        print(f"Found {len(issues)} file(s) with mismatches:\n")
        for issue in issues:
            print(f"  {issue['file']}")
            if issue['missing_events']:
                print(f"    Missing events: {issue['missing_events']}")
            if issue['missing_funcs']:
                print(f"    Missing functions: {issue['missing_funcs']}")
            if issue['missing_structs']:
                print(f"    Missing structs: {issue['missing_structs']}")
            print()
    else:
        print("✓ All solution files match their user files!")

if __name__ == '__main__':
    main()

