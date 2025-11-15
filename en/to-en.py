#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from deep_translator import GoogleTranslator
import re
import os

def is_chinese(text):
    return bool(re.search(r'[\u4e00-\u9fff]', text))

def translate_text(text):
    try:
        return GoogleTranslator(source='zh-CN', target='en').translate(text)
    except Exception as e:
        print(f"\nTranslation error: {e}")
        return text

def translate_line_preserving_variables(line):
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
            translate_text(p) if is_chinese(p) else p
            for p in parts
        ]
        return quote + ''.join(translated_parts) + quote

    return re.sub(r'(?:\'[^\']*\'|"[^"]*")', repl, line)

def translate_file(input_file, output_file):
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
                    translated = translate_text(comment_text)
                    f_out.write(f"{leading_space}{comment_mark} {translated}\n")
                else:
                    f_out.write(line)

            elif any(cmd in stripped for cmd in ['echo', 'read', 'send_stats']) and is_chinese(stripped):
                translated_line = translate_line_preserving_variables(line)
                f_out.write(translated_line)

            else:
                f_out.write(line)

    print("\nTranslation completed.")
    print(f"Original file size: {os.path.getsize(input_file)} bytes")
    print(f"Translated file size: {os.path.getsize(output_file)} bytes")

if __name__ == "__main__":
    input_file = 'kejilion.sh'
    output_file = 'kejilion_en.sh'
    translate_file(input_file, output_file)
