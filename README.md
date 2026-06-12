# ZABAP_TOOLS

> 一个基于 [abapGit](https://docs.abapgit.org/) 管理的 ABAP 工具包，汇集日常开发中常用的报表、工具与增强示例。

## 项目简介

`ZABAP_TOOLS` 致力于打造一个开源、可复用、持续维护的 ABAP 工具集合。所有代码均使用 SAP 客户命名空间（`Z*`）编写，遵循 abapGit 的目录约定，可一键同步到任何标准的 SAP 系统。

### 主要特点

- **按主题分子包**：按照 ALV、增强等不同功能领域划分包结构，便于检索与维护。
- **标准 abapGit 目录**：采用 `FOLDER_LOGIC=PREFIX`，与 SAP 传输请求 / 包的层次结构一一对应。
- **可直接运行的示例**：每段代码都独立可运行，或只需少量调整即可运行。
- **Apache 2.0 开源协议**：欢迎自由使用、修改与再分发（请保留版权声明）。

## 项目结构

```
ZABAP_TOOLS/
├── .abapgit.xml              # abapGit 仓库配置（根包 TOOLS）
├── LICENSE                   # Apache License 2.0
├── README.md                 # 本文件
└── src/                      # ABAP 源代码根目录
    ├── package.devc.xml      # 根包定义（TOOLS）
    ├── alv/                  # ALV 相关工具
    │   ├── package.devc.xml
    │   ├── z_sflight_alv.prog.abap
    │   └── z_sflight_alv.prog.xml
    └── enhancement/          # 增强相关工具
        ├── package.devc.xml
        ├── z_exit_help.prog.abap
        └── z_exit_help.prog.xml
```

## 现有工具一览

| 包 | 程序 | 简介 |
| --- | --- | --- |
| `ZABAP_TOOLS_ALV` | `Z_SFLIGHT_ALV` | 一个简单的 ALV 查询报表 |
| `ZABAP_TOOLS_ENHANCEMENT` | `Z_EXIT_HELP` | 查找增强/出口（User Exit）的辅助工具 |

## 新建包的规则

为保持仓库结构清晰、易于检索，新增包时请遵循以下规范：

### 1. 包路径与命名

- **根包**固定为 `ZABAP_TOOLS`，所有子包都必须以 `ZABAP_TOOLS_` 为前缀命名。
- **目录位置**：所有源码统一放在 `src/` 目录下（abapGit自动管理）。
- **子包文件夹名**使用**英文单词**，简短、表意清晰，建议按功能领域划分，例如：
  - `alv` —— ALV 报表相关
  - `enhancement` —— 增强、用户出口、BAdI 等
  - `bapi` —— BAPI / RFC 接口封装
  - `smartforms` / `adobeforms` —— 表单相关
  - `util` —— 通用工具类与方法
  - `test` —— 测试 Demo

  > 文件夹名即为 SAP 端的子包短名（`PREFIX` 模式），请勿在文件夹名中包含空格或中文。

### 2. 包定义文件

abapGit 自动为每个包创建一个 `package.devc.xml`，用于描述该包：

```xml
<?xml version="1.0" encoding="utf-8"?>
<abapGit version="v1.0.0" serializer="LCL_OBJECT_DEVC" serializer_version="v1.0.0">
 <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
  <asx:values>
   <DEVC>
    <CTEXT>包的中文描述（简洁，不超过 20 字）</CTEXT>
   </DEVC>
  </asx:values>
 </asx:abap>
</abapGit>
```

- `CTEXT`：包描述，使用中文短语。
- 包描述中**禁止**包含敏感信息（客户名、项目号等）。

### 3. ABAP 对象命名规范

| 对象类型 | 文件命名 | 命名约定 | 示例 |
| --- | --- | --- | --- |
| 可执行程序 | `z_*.prog.abap` + `z_*.prog.xml` | `Z_` 前缀，全大写，下划线分隔 | `Z_SFLIGHT_ALV` |
| 类 | `zcl_*.clas.abap` + `zcl_*.clas.xml` | `ZCL_` 前缀 | `ZCL_ALV_UTIL` |
| 接口 | `zif_*.intf.abap` + `zif_*.intf.xml` | `ZIF_` 前缀 | `ZIF_CONSTANTS` |
| 函数组 | `zfg_*.fugr.*` | `ZFG_` 前缀 | `ZFG_STRING_UTIL` |
| 包含程序 | `z_*.prog.abap`（同包内） | 与主程序保持一致前缀 | — |
| 表/结构 | `zt_*.tabl.xml`、`zs_*.stru.xml` | `ZT_` / `ZS_` 前缀 | `ZT_FLIGHT_LOG` |

> **务必使用 `Z*` 客户命名空间**，避免与 SAP 标准对象冲突。

### 4. 代码风格建议

- 每个程序、类在文件头用注释说明：**作者、创建日期、功能简介、关键数据表/类依赖**。
- 公共方法、表单文本元素在 XML 中补充完整，便于他人激活后即可使用。
- 避免硬编码客户端、公司代码等运行环境相关信息；如需配置请使用 `SU3` 用户参数或配置表。
- 不引入与具体客户/项目耦合的业务逻辑，本仓库仅放**通用工具**。

### 5. 提交前自检清单

- [ ] 新代码在 SAP 系统中已**激活**且可正常运行。
- [ ] `abapGit` 重新序列化时没有警告或错误。
- [ ] 确保程序依赖的数据字典完整包含在上传的包中
- [ ] 仅包含 `Z*` 命名空间对象，未误提交 `$*` 标准对象。
- [ ] 不包含客户主数据、密码、密钥等敏感信息。

## 如何使用

### 拉取到本地 SAP 系统

1. 在 SAP GUI 中安装 [abapGit](https://docs.abapgit.org/)（事务码 `ZABAPGIT`，或 `SE38` 运行 `ZABAPGIT_STANDALONE`）。
2. 克隆本仓库的 URL 到本地，abapGit 会按照目录结构在 SAP 端创建对应的包与对象。
3. 激活相关对象后即可使用。

注意：可以根据需要只拉取部分程序（这是 abapGit 支持的功能）

### 拉取到本地浏览

```bash
git clone https://github.com/Jack-Liang/ZABAP_TOOLS.git
cd ZABAP_TOOLS
```

`src/` 下的 `*.abap` 文件可直接在任何编辑器中阅读。

## 贡献指南

🎉 **欢迎同行提交新的代码！** 任何对 ABAP 开发有用的工具、报表、类、函数都可以加入本仓库。

### 提交流程

1. **Fork** 本仓库到自己的 GitHub 账户。
2. 在合适的子包下新建程序或类（遵循上文"新建包的规则"）。
3. 提交时**保持单一主题**：一次 PR 只解决一个问题或新增一个工具，便于 Code Review。
4. 在 PR 描述中写明：
   - 新增/修改的对象列表（包路径 + 程序名）。
   - 该工具的用途与适用场景。
   - 是否依赖特定 SAP 版本（如 `S4HANA 2022`、`ECC 6.0 EHP8`）。
   - 截图或操作示例（如有）。
5. 等待维护者 Review，按反馈调整后合并。

### 行为准则

- 提交的代码必须是您本人原创或有权分发的内容。
- 严禁提交包含客户数据、密码、生产配置等敏感信息的代码。
- 尊重他人的代码风格，遵循本仓库既有的命名与目录约定。
- 对于争议性设计，建议先在 Issue 区发起讨论。

### 贡献方向建议

特别欢迎以下方向的新工具：

- 🚀 ALV、Smart Forms、Adobe Forms 的常用模板
- 🔍 通用查询 / 数据导出工具
- 🛠 BAdI、User Exit 增强示例
- 📊 性能分析、SQL 跟踪辅助
- 🔐 权限、传输请求、版本管理相关脚本
- 📦 OO 封装的基础工具类（字符串、日期、Internal Table 操作等）

## 版本与兼容

- 推荐 SAP BASIS **740** 及以上版本。
- 部分语法（如字符串模板、内联声明）在更低版本上可能不兼容，提交时需注明。

## 许可证

本项目基于 [Apache License 2.0](LICENSE) 开源，您可以自由使用、修改、分发，但请保留原作者声明。

## 联系方式

- 作者：Jack.Liang
- 仓库地址：`https://github.com/Jack-Liang/ZABAP_TOOLS.git`

如有问题或建议，欢迎在 Issue 区留言，或直接提交 PR。
