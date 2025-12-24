#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from deep_translator import GoogleTranslator
import re
import os
import sys

def is_chinese(text):
    return bool(re.search(r'[\u4e00-\u9fff]', text))

def translate_text(text, target_lang):
    if not text.strip() or not is_chinese(text):
        return text
    try:
        return GoogleTranslator(source='zh-CN', target=target_lang).translate(text)
    except Exception as e:
        print(f"\nTranslation error: {e}")
        return text

def translate_line_preserving_variables(line, target_lang):
    """
    处理 echo/read/send_stats 等命令中的中文，同时保护其中的 ${var}
    """
    def repl(match):
        full_string = match.group(0)
        quote = full_string[0]
        content = full_string[1:-1]
        # 分割出变量，只翻译非变量部分
        parts = re.split(r'(\$\{?\w+\}?)', content)
        translated_parts = [
            translate_text(p, target_lang) if is_chinese(p) else p
            for p in parts
        ]
        return quote + ''.join(translated_parts) + quote
    
    return re.sub(r'(?:\'[^\']*\'|"[^"]*")', repl, line)

def translate_assignment_value(line, target_lang):
    """
    专门处理变量赋值语句：VAR="中文内容" -> VAR="Translated Content"
    """
    # 匹配 key="value" 或 key='value' 格式，且 value 包含中文
    match = re.match(r'^(\s*[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*)([\'"])(.*)([\'"])(.*)$', line)
    if match:
        prefix, quote_open, value, quote_close, suffix = match.groups()
        if is_chinese(value):
            # 同样要保护赋值内容里的 ${var}
            parts = re.split(r'(\$\{?\w+\}?)', value)
            translated_value = "".join([
                translate_text(p, target_lang) if is_chinese(p) else p 
                for p in parts
            ])
            return f"{prefix}{quote_open}{translated_value}{quote_close}{suffix}\n"
    return line

def translate_file(input_file, output_file, target_lang):
    print(f"Translating to {target_lang}...")
    
    if not os.path.exists(input_file):
        print(f"Error: Input file {input_file} not found")
        return False
    
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    total_lines = len(lines)
    
    with open(output_file, 'w', encoding='utf-8') as f_out:
        for i, line in enumerate(lines):
            progress = (i + 1) / total_lines * 100
            print(f"\rProcessing: {progress:.1f}% ({i+1}/{total_lines})", end='')
            
            leading_space = re.match(r'^(\s*)', line).group(1)
            stripped = line.strip()
            
            # 1. 处理注释
            if stripped.startswith('#') and is_chinese(stripped):
                comment_text = stripped[1:].strip()
                if comment_text:
                    translated = translate_text(comment_text, target_lang)
                    f_out.write(f"{leading_space}# {translated}\n")
                else:
                    f_out.write(line)
            
            # 2. 处理常用交互命令
            elif any(cmd in stripped for cmd in ['echo', 'read', 'send_stats']) and is_chinese(stripped):
                f_out.write(translate_line_preserving_variables(line, target_lang))
            
            # 3. 处理变量赋值中的中文 (新增强化)
            elif '=' in stripped and is_chinese(stripped):
                f_out.write(translate_assignment_value(line, target_lang))
            
            # 4. 其他行原样保留
            else:
                f_out.write(line)
    
    print(f"\nTranslation to {target_lang} completed.")
    return True

if __name__ == "__main__":
    input_file = 'kejilion.sh'
    languages = {'en': 'en', 'tw': 'zh-TW', 'kr': 'ko', 'jp': 'ja'}
    
    success_count = 0
    for dir_name, lang_code in languages.items():
        output_file = f'{dir_name}/kejilion.sh'
        if translate_file(input_file, output_file, lang_code):
            success_count += 1
            print(f"✓ {dir_name} done")
        print("-" * 30)
    
    if success_count == 0: sys.exit(1)
