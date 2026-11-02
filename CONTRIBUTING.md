# 贡献与同步规则

## 主脚本与中文脚本

- 修改根目录 `kejilion.sh` 的业务逻辑、协议、命令、依赖或修复时，必须在同一提交中同步更新 `cn/kejilion.sh`。
- 两份脚本除区域入口参数外必须保持一致：根脚本使用 `canshu="default"`，中文脚本使用 `canshu="CN"`。
- 提交前必须运行：

  ```bash
  bash tests/test_cn_script_sync.sh
  ```

- 同步检查失败时不得合并或发布；不能通过跳过测试、复制旧版脚本或仅修改其中一份来规避。

## WAF 稳定引导器

`scripts/waf_runtime.py` 是两份脚本内嵌更新器的唯一编辑来源；修改后运行 `python3 scripts/embed_waf_runtime.py`，提交前运行 `--check`、`tests/test_shared_waf_bootstrap.py`、根/CN同步检查及受影响的隔离集成。脚本内的固定七文件摘要只作为一次性旧安装迁移基线，不是稳定通道的最新版指针；后续共享包发布不修改它。

共享包发布工具、API 1兼容契约、签名清单和回滚要求位于 nginx 仓库的 `waf/README.md`。不得绕过签名校验，也不得把脚本发布当作共享包自动升级。引导器公钥轮换需要新的脚本版本；私钥不入库、不上传试点主机。

## KPanel 轻量节点运行时契约

- 安装器与生成的更新器共用 `KPANEL_NODE_LIFECYCLE` 模板；不可另写一份锁逻辑。
- 修改更新器、共用锁或 update service/timer 模板时，递增
  `KPANEL_NODE_RUNTIME_GENERATION`，并同步 KPanel 的嵌入模板及其来源校验。
  此数字只用于阻止旧资产回写较新的运行时，不是脚本发布版本号。
- 不删除 `/run/kejilion-node-lifecycle.lock`；卸载保留这个空锁文件，避免锁 inode
  被替换造成两个并发所有者。锁由内核释放，旧 mkdir 锁只允许核对进程后移除空目录。
