import os

def check_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
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
            stack.append(line_num)
            i += 1
        elif char == "}":
            if stack:
                stack.pop()
            else:
                return f"Extra closing brace at line {line_num}"
            i += 1
        else:
            i += 1

    if stack:
        return f"Unclosed braces started at lines: {stack}"
    return None

qml_dir = "C:/Programacion/Rescate_Proyecto/src/ui/qml"
for root, dirs, files in os.walk(qml_dir):
    for file in files:
        if file.endswith(".qml"):
            path = os.path.join(root, file).replace("\\", "/")
            res = check_file(path)
            if res:
                print(f"File: {path}\n  -> {res}")
            else:
                print(f"File: {path} is OK")
