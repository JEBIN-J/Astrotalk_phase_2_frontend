import re
file_path = r'astro_app\lib\screens\horoscope_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Use regex to replace just the fallback value
pattern = r'(_kundliData\?\[.ayanamsa_formatted.\].*toString\(\) \?\? )"[^"]*"'
replacement = r'\1_selectedAyanamsa'
new_content = re.sub(pattern, replacement, content)

if new_content != content:
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print('Fixed using regex.')
else:
    print('Still not found')
    idx = content.find('ayanamsa_formatted')
    print(repr(content[idx-20:idx+120]))
