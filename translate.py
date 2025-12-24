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
        # 过滤掉一些不该翻译的特殊符号
        clean_text = text.strip()
        result = GoogleTranslator(source='zh-CN', target=target_lang).translate(clean_text)
        return result
    except Exception as e:
        print(f"\n[Error] {e}")
        return text

def process_content_with_vars(content, target_lang):
    """
    核心逻辑：保护 ${var} 和 $var，翻译其中的中文部分
    """
    # 匹配 ${var} 或 $var (字母数字下划线)
    parts = re.split(r'(\$\{\w+\}|\$\w+)', content)
    translated_parts = []
    for p in parts:
        if p.startswith('$'): # 变量部分，保持原样
            translated_parts.append(p)
        elif is_chinese(p): # 中文部分，翻译
            translated_parts.append(translate_text(p, target_lang))
        else: # 其他英文/符号，保持原样
            translated_parts.append(p)
    return "".join(translated_parts)

def universal_translator(line, target_lang):
    """
    通用翻译引擎：识别行内所有引号内容并翻译
    """
    # 1. 保护注释行
    leading_space = re.match(r'^(\s*)', line).group(1)
    stripped = line.strip()
    if stripped.startswith('#'):
        comment_content = stripped[1:].strip()
        if is_chinese(comment_content):
            return f"{leading_space}# {translate_text(comment_content, target_lang)}\n"
        return line

    # 2. 识别所有引号内的内容 (双引号或单引号)
    # 使用正则匹配引号对，同时处理转义引号 \"
    def replacer(match):
        quote_type = match.group(1) # ' 或 "
        content = match.group(2)    # 引号内的文本内容
        if is_chinese(content):
            # 翻译内容，但保护里面的变量
            translated = process_content_with_vars(content, target_lang)
            return f"{quote_type}{translated}{quote_type}"
        return match.group(0)

    # 匹配 "content" 或 'content'
    new_line = re.sub(r'([\'"])(.*?)(?<!\\)\1', replacer, line)
    return new_line

def translate_file(input_file, output_file, target_lang):
    print(f"Translating to {target_lang}...")
    if not os.path.exists(input_file): return False
    
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    total = len(lines)
    with open(output_file, 'w', encoding='utf-8') as f_out:
        for i, line in enumerate(lines):
            if (i + 1) % 10 == 0 or i + 1 == total:
                print(f"\rProgress: {(i+1)/total*100:.1f}%", end='')
            
            # 只要行内有中文，就尝试用通用引擎翻译
            if is_chinese(line):
                f_out.write(universal_translator(line, target_lang))
            else:
                f_out.write(line)
    print(f"\n{target_lang} Success.")
    return True

if __name__ == "__main__":
    input_file = 'kejilion.sh'
    langs = {'en': 'en', 'tw': 'zh-TW', 'kr': 'ko', 'jp': 'ja'}
    for dir_name, lang_code in langs.items():
        translate_file(input_file, f'{dir_name}/kejilion.sh', lang_code)
