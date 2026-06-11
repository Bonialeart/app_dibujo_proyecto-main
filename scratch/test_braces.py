with open("C:/Programacion/Rescate_Proyecto/src/ui/qml/views/CanvasPage.qml", "r", encoding="utf-8") as f:
    content = f.read()

stack = []
i = 0
line_num = 1
in_string = None
in_block_comment = False
in_line_comment = False

while i < len(content):
    char = content[i]
    next_char = content[i+1] if i + 1 < len(content) else ""
    if char == "\n":
        line_num += 1
        in_line_comment = False
        i += 1
        continue
    if in_line_comment:
        i += 1
        continue
    if in_block_comment:
        if char == "*" and next_char == "/":
            in_block_comment = False
            i += 2
        else:
            i += 1
        continue
    if in_string:
        if char == "\\":
            i += 2
        elif char == in_string:
            in_string = None
            i += 1
        else:
            i += 1
        continue
    if char == "/" and next_char == "/":
        in_line_comment = True
        i += 2
    elif char == "/" and next_char == "*":
        in_block_comment = True
        i += 2
    elif char in ('"', "'", '`'):
        in_string = char
        i += 1
    elif char == "{":
        line_start = content.rfind("\n", 0, i) + 1
        line_end = content.find("\n", i)
        line_text = content[line_start:line_end].strip()
        stack.append((line_num, line_text))
        i += 1
    elif char == "}":
        if stack:
            popped = stack.pop()
            if popped[0] == 15:
                print(f"Popped root Item (line 15) at line {line_num}")
        else:
            print(f"Extra closing brace at line {line_num}")
        i += 1
    else:
        i += 1

print("\n--- End of file states ---")
print("Remaining open braces count:", len(stack))
for line, text in stack:
    print(f"Line {line}: {text}")
