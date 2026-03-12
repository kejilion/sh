#!/usr/bin/env bash
set -euo pipefail

# 模拟脚本原生颜色变量
# shellcheck disable=SC2034
gl_hong='\033[31m'
# shellcheck disable=SC2034
gl_lv='\033[32m'
# shellcheck disable=SC2034
gl_huang='\033[33m'
# shellcheck disable=SC2034
gl_bai='\033[0m'

printf '%s\n' '--- OpenClaw API 列表（最小颜色/对齐验证） ---'
printf '%-4s %-18s %-44s %-8s %-12s\n' '序号' '名称' 'API地址' '模型数量' '延迟/状态'
printf '%s\n' '----------------------------------------------------------------------------------------------'

# 模拟 Python 计算后的字段（纯数据，不含颜色码）
while IFS=$'\t' read -r rec_type idx name base_url model_count latency_txt latency_level; do
  [[ "$rec_type" == "ROW" ]] || continue

  latency_color="$gl_bai"
  case "$latency_level" in
    low) latency_color="$gl_lv" ;;
    medium) latency_color="$gl_huang" ;;
    high|unavailable) latency_color="$gl_hong" ;;
    unchecked) latency_color="$gl_bai" ;;
  esac

  # 颜色在 Shell 层拼接并输出
  printf '%-4s %-18s %-44s %b%-8s%b %b%-12s%b\n' \
    "$idx" "$name" "$base_url" \
    "$gl_huang" "$model_count" "$gl_bai" \
    "$latency_color" "$latency_txt" "$gl_bai"
done <<'EOF'
ROW	1.	alpha-openai	https://api.alpha.example/v1	128	120ms	low
ROW	2.	beta-proxy	https://api.beta.example/v1	64	1300ms	medium
ROW	3.	gamma-down	https://api.gamma.example/v1	0	不可用	unavailable
ROW	4.	delta-custom	-	12	未检测	unchecked
EOF
