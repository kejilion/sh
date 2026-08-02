# 贡献与同步规则

## 主脚本与中文脚本

- 修改根目录 `kejilion.sh` 的业务逻辑、协议、命令、依赖或修复时，必须在同一提交中同步更新 `cn/kejilion.sh`。
- 两份脚本除区域入口参数外必须保持一致：根脚本使用 `canshu="default"`，中文脚本使用 `canshu="CN"`。
- 提交前必须运行：

  ```bash
  bash tests/test_cn_script_sync.sh
  ```

- 同步检查失败时不得合并或发布；不能通过跳过测试、复制旧版脚本或仅修改其中一份来规避。
