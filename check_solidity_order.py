#!/usr/bin/env python3
"""
Script to check and reorder Solidity files according to canonical order:
1. SPDX + pragma
2. Imports
3. Contract/interface/library declarations
4. Type declarations (enums, structs) - INSIDE contract
5. State variables (constants, immutables, then regular storage vars)
6. Events
7. Modifiers
8. Constructor
9. Receive/fallback functions
10. External functions
11. Public functions
12. Internal functions
13. Private functions
14. View/pure helper functions
15. Custom errors (can be with events or after state variables)
"""

import re
import sys
from pathlib import Path
from typing import List, Tuple, Dict

def parse_solidity_file(content: str) -> Dict:
    """Parse a Solidity file into sections."""
    lines = content.split('\n')
    
    sections = {
        'spdx_pragma': [],
        'imports': [],
        'contract_declaration': [],
        'enums': [],
        'structs': [],
        'constants': [],
        'immutables': [],
        'state_vars': [],
        'custom_errors': [],
        'events': [],
        'modifiers': [],
        'constructor': [],
        'receive_fallback': [],
        'external_functions': [],
        'public_functions': [],
        'internal_functions': [],
        'private_functions': [],
        'other': []
    }
    
    i = 0
    current_section = 'spdx_pragma'
    brace_count = 0
    in_contract = False
    
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        
        # SPDX and pragma
        if stripped.startswith('// SPDX') or stripped.startswith('pragma solidity'):
            sections['spdx_pragma'].append(line)
            i += 1
            continue
        
        # Imports
        if stripped.startswith('import '):
            sections['imports'].append(line)
            i += 1
            continue
        
        # Contract/interface/library declaration
        if re.match(r'^(contract|interface|library|abstract contract)', stripped):
            in_contract = True
            sections['contract_declaration'].append(line)
            brace_count += stripped.count('{') - stripped.count('}')
            i += 1
            continue
        
        if not in_contract:
            sections['other'].append(line)
            i += 1
            continue
        
        # Track braces
        brace_count += stripped.count('{') - stripped.count('}')
        
        # Enums
        if re.match(r'^\s*enum\s+\w+', stripped):
            enum_lines = [line]
            i += 1
            while i < len(lines) and brace_count > 0:
                enum_lines.append(lines[i])
                brace_count += lines[i].count('{') - lines[i].count('}')
                i += 1
            sections['enums'].extend(enum_lines)
            continue
        
        # Structs
        if re.match(r'^\s*struct\s+\w+', stripped):
            struct_lines = [line]
            i += 1
            while i < len(lines) and brace_count > 0:
                struct_lines.append(lines[i])
                brace_count += lines[i].count('{') - lines[i].count('}')
                i += 1
            sections['structs'].extend(struct_lines)
            continue
        
        # Custom errors
        if re.match(r'^\s*error\s+\w+', stripped):
            error_lines = [line]
            i += 1
            while i < len(lines) and not lines[i].strip().endswith(';'):
                error_lines.append(lines[i])
                i += 1
            if i < len(lines):
                error_lines.append(lines[i])
            sections['custom_errors'].extend(error_lines)
            i += 1
            continue
        
        # Events
        if re.match(r'^\s*event\s+\w+', stripped):
            event_lines = [line]
            i += 1
            while i < len(lines) and not lines[i].strip().endswith(';'):
                event_lines.append(lines[i])
                i += 1
            if i < len(lines):
                event_lines.append(lines[i])
            sections['events'].extend(event_lines)
            i += 1
            continue
        
        # Modifiers
        if re.match(r'^\s*modifier\s+\w+', stripped):
            modifier_lines = [line]
            i += 1
            while i < len(lines) and brace_count > 0:
                modifier_lines.append(lines[i])
                brace_count += lines[i].count('{') - lines[i].count('}')
                i += 1
            sections['modifiers'].extend(modifier_lines)
            continue
        
        # Constructor
        if re.match(r'^\s*constructor\s*\(', stripped):
            constructor_lines = [line]
            i += 1
            while i < len(lines) and brace_count > 0:
                constructor_lines.append(lines[i])
                brace_count += lines[i].count('{') - lines[i].count('}')
                i += 1
            sections['constructor'].extend(constructor_lines)
            continue
        
        # Receive/fallback
        if re.match(r'^\s*(receive|fallback)\s*\(', stripped):
            func_lines = [line]
            i += 1
            while i < len(lines) and brace_count > 0:
                func_lines.append(lines[i])
                brace_count += lines[i].count('{') - lines[i].count('}')
                i += 1
            sections['receive_fallback'].extend(func_lines)
            continue
        
        # Functions
        func_match = re.match(r'^\s*function\s+\w+', stripped)
        if func_match:
            func_lines = [line]
            func_start = i
            i += 1
            local_brace_count = brace_count
            while i < len(lines) and local_brace_count > 0:
                func_lines.append(lines[i])
                local_brace_count += lines[i].count('{') - lines[i].count('}')
                i += 1
            
            # Determine function visibility
            func_text = '\n'.join(func_lines)
            if 'external' in func_text:
                sections['external_functions'].extend(func_lines)
            elif 'public' in func_text:
                sections['public_functions'].extend(func_lines)
            elif 'internal' in func_text:
                sections['internal_functions'].extend(func_lines)
            elif 'private' in func_text:
                sections['private_functions'].extend(func_lines)
            else:
                # Default to public if no visibility specified
                sections['public_functions'].extend(func_lines)
            continue
        
        # Constants
        if 'constant' in stripped and not stripped.startswith('//'):
            sections['constants'].append(line)
            i += 1
            continue
        
        # Immutables
        if 'immutable' in stripped and not stripped.startswith('//'):
            sections['immutables'].append(line)
            i += 1
            continue
        
        # State variables (public/private/internal mappings, arrays, etc.)
        if re.match(r'^\s*(mapping|uint|int|bool|address|string|bytes|array)', stripped) or \
           re.match(r'^\s*\w+\s+(public|private|internal)', stripped):
            sections['state_vars'].append(line)
            i += 1
            continue
        
        sections['other'].append(line)
        i += 1
    
    return sections

def reorder_solidity_file(content: str) -> str:
    """Reorder a Solidity file according to canonical order."""
    sections = parse_solidity_file(content)
    
    result = []
    
    # 1. SPDX + pragma
    result.extend(sections['spdx_pragma'])
    if sections['spdx_pragma']:
        result.append('')
    
    # 2. Imports
    result.extend(sections['imports'])
    if sections['imports']:
        result.append('')
    
    # 3. Contract declaration start
    result.extend(sections['contract_declaration'])
    
    # 4. Type declarations (enums, structs)
    if sections['enums']:
        result.extend(sections['enums'])
        result.append('')
    if sections['structs']:
        result.extend(sections['structs'])
        result.append('')
    
    # 5. State variables (constants, immutables, then regular)
    if sections['constants']:
        result.extend(sections['constants'])
        result.append('')
    if sections['immutables']:
        result.extend(sections['immutables'])
        result.append('')
    if sections['state_vars']:
        result.extend(sections['state_vars'])
        result.append('')
    
    # 6. Custom errors (can be here or with events)
    if sections['custom_errors']:
        result.extend(sections['custom_errors'])
        result.append('')
    
    # 7. Events
    if sections['events']:
        result.extend(sections['events'])
        result.append('')
    
    # 8. Modifiers
    if sections['modifiers']:
        result.extend(sections['modifiers'])
        result.append('')
    
    # 9. Constructor
    if sections['constructor']:
        result.extend(sections['constructor'])
        result.append('')
    
    # 10. Receive/fallback
    if sections['receive_fallback']:
        result.extend(sections['receive_fallback'])
        result.append('')
    
    # 11. External functions
    if sections['external_functions']:
        result.extend(sections['external_functions'])
        result.append('')
    
    # 12. Public functions
    if sections['public_functions']:
        result.extend(sections['public_functions'])
        result.append('')
    
    # 13. Internal functions
    if sections['internal_functions']:
        result.extend(sections['internal_functions'])
        result.append('')
    
    # 14. Private functions
    if sections['private_functions']:
        result.extend(sections['private_functions'])
        result.append('')
    
    # 15. Other (comments, etc.)
    result.extend(sections['other'])
    
    return '\n'.join(result)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python check_solidity_order.py <file.sol>")
        sys.exit(1)
    
    file_path = Path(sys.argv[1])
    if not file_path.exists():
        print(f"File not found: {file_path}")
        sys.exit(1)
    
    content = file_path.read_text()
    reordered = reorder_solidity_file(content)
    
    print(reordered)

