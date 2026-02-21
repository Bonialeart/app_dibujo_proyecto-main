
import sys

def check_braces(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    balance = 0
    line_num = 1
    for char in content:
        if char == '{':
            balance += 1
        elif char == '}':
            balance -= 1
        if char == '\n':
            line_num += 1
        
        if balance < 0:
            print(f"Extra closing brace found at line {line_num}")
            return
    
    if balance > 0:
        print(f"Missing {balance} closing braces")
    elif balance < 0:
        print(f"Missing {abs(balance)} opening braces")
    else:
        print("Braces are balanced")

if __name__ == "__main__":
    check_braces(sys.argv[1])
