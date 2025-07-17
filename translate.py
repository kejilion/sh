#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from deep_translator import GoogleTranslator
import re
import os
import sys

def is_chinese(text):
    return bool(re.search(r'[\u4e00-\u9fff]', text))

def translate_text(text, target_lang):
    try:
        return GoogleTranslator(source='zh-CN', target=target_lang).translate(text)
    except Exception as e:
        print(f"\nTranslation error: {e}")
        return text

def translate_line_preserving_variables(line, target_lang):
    """
    Translate only Chinese parts in echo/read/send_stats commands, excluding shell variables
    """
    # Match double or single quoted strings
    def repl(match):
        full_string = match.group(0)
        quote = full_string[0]
        content = full_string[1:-1]
        # Split by variable expressions
        parts = re.split(r'(\$\{?\w+\}?)', content)
        translated_parts = [
            translate_text(p, target_lang) if is_chinese(p) else p
            for p in parts
        ]
        return quote + ''.join(translated_parts) + quote
    
    return re.sub(r'(?:\'[^\']*\'|"[^"]*")', repl, line)

def translate_file(input_file, output_file, target_lang):
    print(f"Translating to {target_lang}...")
    
    if not os.path.exists(input_file):
        print(f"Error: Input file {input_file} not found")
        return False
    
    total_lines = sum(1 for _ in open(input_file, 'r', encoding='utf-8'))
    processed_lines = 0
    
    with open(input_file, 'r', encoding='utf-8') as f_in, \
         open(output_file, 'w', encoding='utf-8') as f_out:
        
        for line in f_in:
            processed_lines += 1
            progress = processed_lines / total_lines * 100
            print(f"\rProcessing: {progress:.1f}% ({processed_lines}/{total_lines})", end='')
            
            leading_space = re.match(r'^(\s*)', line).group(1)
            stripped = line.strip()
            
            if stripped.startswith('#') and is_chinese(stripped):
                comment_mark = '#'
                comment_text = stripped[1:].strip()
                if comment_text:
                    translated = translate_text(comment_text, target_lang)
                    f_out.write(f"{leading_space}{comment_mark} {translated}\n")
                else:
                    f_out.write(line)
            elif any(cmd in stripped for cmd in ['echo', 'read', 'send_stats']) and is_chinese(stripped):
                translated_line = translate_line_preserving_variables(line, target_lang)
                f_out.write(translated_line)
            else:
                f_out.write(line)
    
    print(f"\nTranslation to {target_lang} completed.")
    print(f"Original file size: {os.path.getsize(input_file)} bytes")
    print(f"Translated file size: {os.path.getsize(output_file)} bytes")
    return True

if __name__ == "__main__":
    input_file = 'kejilion.sh'
    
    # 语言映射：目录名 -> Google翻译语言代码
    languages = {
        'en': 'en',      # 英语
        'tw': 'zh-TW',   # 繁体中文
        'kr': 'ko',      # 韩语
        'jp': 'ja'       # 日语
    }
    
    success_count = 0
    
    for dir_name, lang_code in languages.items():
        output_file = f'{dir_name}/kejilion.sh'
        if translate_file(input_file, output_file, lang_code):
            success_count += 1
            print(f"✓ Successfully translated to {dir_name}")
        else:
            print(f"✗ Failed to translate to {dir_name}")
        print("-" * 50)
    
    print(f"\nTranslation summary: {success_count}/{len(languages)} languages completed")
    
    if success_count == 0:
        sys.exit(1)
