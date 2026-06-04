import re
import ast

with open('WinkForeverVipCrack.js', 'r', encoding='utf-8') as f:
    text = f.read()

match = re.search(r'var __Oxfe574=\[(.*?)\];', text)
if match:
    arr_str = '[' + match.group(1) + ']'
    arr = ast.literal_eval(arr_str)
    
    def replacer(m):
        idx_str = m.group(1)
        idx = int(idx_str, 16) if idx_str.startswith('0x') else int(idx_str)
        val = arr[idx]
        if isinstance(val, str):
            val = val.replace('"', '\\"').replace('\n', '\\n')
            return f'"{val}"'
        return str(val)
    
    text = re.sub(r'__Oxfe574\[(0x[0-9a-fA-F]+|[0-9]+)\]', replacer, text)
    text = re.sub(r'var __Oxfe574=\[.*?\];', '', text)

# Giải mã \x và \u nếu còn
def hex_replacer(m):
    return chr(int(m.group(1), 16))
text = re.sub(r'\\x([0-9a-fA-F]{2})', hex_replacer, text)

# Pretty print bằng jsbeautifier nếu có thể
import jsbeautifier
res = jsbeautifier.beautify(text)

with open('WinkForeverVipCrack_Decoded.js', 'w', encoding='utf-8') as f:
    f.write(res)

print("Decoded successfully!")
