#!/bin/bash
################################################################################
# Dify 工作流定时调度脚本
# 功能：定时调用 Dify 工作流 API，并记录详细日志
# 作者：自动生成
# 日期：2025-10-05
################################################################################

set -euo pipefail  # 严格模式：遇到错误立即退出

################################################################################
# 配置区域
################################################################################

# 默认配置（可通过环境变量覆盖）
DIFY_BASE_URL="${DIFY_BASE_URL:-http://dify.zhikeyun.top/v1}"
DIFY_API_ENDPOINT="${DIFY_API_ENDPOINT:-/workflows/run}"  # API 端点
DIFY_TOKEN="${DIFY_TOKEN:-app-iLMJsIwzwD0nEf007R5QYWPc}"
DIFY_INPUTS="${DIFY_INPUTS:-{}}"  # 工作流输入参数（JSON 格式）
DIFY_USER="${DIFY_USER:-root}"
DIFY_RESPONSE_MODE="${DIFY_RESPONSE_MODE:-streaming}"

# 日志配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/dify-schedule.log"
MAX_LOG_SIZE=$((10 * 1024 * 1024))  # 10MB

# 颜色定义（用于终端输出）
COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_CYAN='\033[0;36m'

################################################################################
# 工具函数
################################################################################

# 日志函数：同时输出到终端和文件
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[${timestamp}] [${level}] ${message}"

    # 确保日志目录存在
    mkdir -p "${LOG_DIR}"

    # 输出到日志文件
    echo "${log_entry}" >> "${LOG_FILE}"

    # 根据级别输出到终端（带颜色）
    case "${level}" in
        INFO)
            echo -e "${COLOR_BLUE}${log_entry}${COLOR_RESET}"
            ;;
        SUCCESS)
            echo -e "${COLOR_GREEN}${log_entry}${COLOR_RESET}"
            ;;
        WARN)
            echo -e "${COLOR_YELLOW}${log_entry}${COLOR_RESET}"
            ;;
        ERROR)
            echo -e "${COLOR_RED}${log_entry}${COLOR_RESET}"
            ;;
        *)
            echo "${log_entry}"
            ;;
    esac
}

# 错误处理函数
error_exit() {
    log ERROR "$1"
    exit 1
}

# 日志轮转函数
rotate_log() {
    if [[ -f "${LOG_FILE}" ]]; then
        local log_size
        log_size=$(stat -f%z "${LOG_FILE}" 2>/dev/null || stat -c%s "${LOG_FILE}" 2>/dev/null || echo 0)

        if [[ ${log_size} -gt ${MAX_LOG_SIZE} ]]; then
            local archive_name="${LOG_FILE}.$(date '+%Y%m%d_%H%M%S')"
            mv "${LOG_FILE}" "${archive_name}"
            log INFO "日志文件已归档: ${archive_name}"
        fi
    fi
}

################################################################################
# 前置检查
################################################################################

check_dependencies() {
    log INFO "检查依赖..."

    # 检查 curl
    if ! command -v curl &> /dev/null; then
        error_exit "未找到 curl 命令，请先安装: apt-get install curl 或 yum install curl"
    fi

    # 检查 jq（可选，用于 JSON 解析）
    if ! command -v jq &> /dev/null; then
        log WARN "未找到 jq 命令，将无法解析 JSON 响应。建议安装: apt-get install jq"
    fi

    log SUCCESS "依赖检查通过"
}

check_config() {
    log INFO "检查配置..."

    # 检查必需的环境变量
    if [[ -z "${DIFY_BASE_URL}" ]]; then
        error_exit "DIFY_BASE_URL 未配置"
    fi

    if [[ -z "${DIFY_TOKEN}" ]]; then
        error_exit "DIFY_TOKEN 未配置"
    fi

    log INFO "Dify API 地址: ${DIFY_BASE_URL}"
    log INFO "Dify Token: ${DIFY_TOKEN:0:10}..."
    log SUCCESS "配置检查通过"
}

################################################################################
# 主逻辑
################################################################################

call_dify_api() {
    log INFO "========== 开始执行 Dify 工作流 =========="
    log INFO "请求参数: inputs=${DIFY_INPUTS}, user=${DIFY_USER}, response_mode=${DIFY_RESPONSE_MODE}"

    # 构建完整的 API URL
    local api_url="${DIFY_BASE_URL}${DIFY_API_ENDPOINT}"
    log INFO "API 地址: ${api_url}"

    # 构建请求体（工作流 API 不需要 query 和 conversation_id）
    local request_body
    request_body=$(cat <<EOF
{
    "inputs": ${DIFY_INPUTS},
    "response_mode": "${DIFY_RESPONSE_MODE}",
    "user": "${DIFY_USER}"
}
EOF
)

    log INFO "发送 API 请求..."

    # 调用 API（保存响应和状态码）
    local response_file="${LOG_DIR}/response_$(date '+%Y%m%d_%H%M%S').json"
    local http_code

    http_code=$(curl -X POST "${api_url}" \
        --header "Authorization: Bearer ${DIFY_TOKEN}" \
        --header "Content-Type: application/json" \
        --data-raw "${request_body}" \
        --silent \
        --show-error \
        --write-out "%{http_code}" \
        --output "${response_file}" \
        2>&1 || echo "000")

    log INFO "HTTP 状态码: ${http_code}"

    # 检查响应状态码
    if [[ "${http_code}" -ge 200 && "${http_code}" -lt 300 ]]; then
        log SUCCESS "API 调用成功"

        # 解析响应（如果安装了 jq）
        if command -v jq &> /dev/null; then
            log INFO "解析响应内容..."
            if jq . "${response_file}" > /dev/null 2>&1; then
                log INFO "响应内容:"
                jq . "${response_file}" | while IFS= read -r line; do
                    log INFO "  ${line}"
                done
            else
                log WARN "响应不是有效的 JSON 格式"
                log INFO "原始响应: $(cat "${response_file}")"
            fi
        else
            log INFO "原始响应已保存到: ${response_file}"
        fi

        log SUCCESS "========== 执行完成 =========="
        return 0
    else
        log ERROR "API 调用失败，HTTP 状态码: ${http_code}"
        log ERROR "响应内容: $(cat "${response_file}")"
        log ERROR "========== 执行失败 =========="
        return 1
    fi
}

################################################################################
# 主程序入口
################################################################################

main() {
    # 日志轮转
    rotate_log

    log INFO "=========================================="
    log INFO "Dify 工作流定时调度脚本启动"
    log INFO "=========================================="

    # 加载 .env 文件（如果存在）
    if [[ -f "${SCRIPT_DIR}/.env" ]]; then
        log INFO "加载 .env 配置文件..."
        # shellcheck disable=SC1091
        source "${SCRIPT_DIR}/.env"
    fi

    # 前置检查
    check_dependencies
    check_config

    # 调用 API
    if call_dify_api; then
        log SUCCESS "脚本执行成功"
        exit 0
    else
        log ERROR "脚本执行失败"
        exit 1
    fi
}

# 捕获中断信号
trap 'log WARN "脚本被中断"; exit 130' INT TERM

# 执行主程序
main "$@"