file_path = r'astro_app\lib\screens\horoscope_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_line = '''    final ayanamsa = _kundliData?['ayanamsa_formatted']?.toString() ?? "Lahiri 23\u00c2\u00b0 50' 32\\"";'''
new_line = '''    final ayanamsa = _kundliData?['ayanamsa_formatted']?.toString() ?? _selectedAyanamsa;'''

if old_line in content:
    content = content.replace(old_line, new_line)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Fixed hardcoded Lahiri fallback in horoscope_screen.dart')
else:
    # Try a different encoding of the degree symbol
    import re
    pattern = r'''    final ayanamsa = _kundliData\?.\['ayanamsa_formatted'\].*toString\(\) \?\? "Lahiri.*";'''
    replacement = '''    final ayanamsa = _kundliData?['ayanamsa_formatted']?.toString() ?? _selectedAyanamsa;'''
    new_content = re.sub(pattern, replacement, content)
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print('Fixed using regex.')
    else:
        print('Pattern not found, showing sample of actual content around Lahiri:')
        idx = content.find('Lahiri 23')
        print(repr(content[idx-100:idx+100]))
