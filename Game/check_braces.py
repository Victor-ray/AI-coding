# Read the current CardUI.gd, check for brace characters
with open('E:/claude-code-demo/game_demo/狱火爬升3.0/狱火爬升/Scripts/CardUI.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Find lines containing potential brace-like characters
for i, line in enumerate(content.split('\n'), 1):
    for j, c in enumerate(line):
        o = ord(c)
        if o > 127 and o < 256:
            print(f"Line {i}, Col {j}: char '{c}' ord={o} hex={hex(o)}")
            if o == 0x7b or o == 0x7d:
                print("  FOUND BRACE CHAR!")
                break
    # Also print any line with tabs converted
    if '\t' in line:
        print(f"Line {i} has TABs")

# Count braces
open_braces = content.count('{')
close_braces = content.count('}')
print(f"open_braces = {open_braces}, close_braces = {close_braces}")
print(f"file size = {len(content)}")