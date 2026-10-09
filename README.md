# ML Assignment 2：项目说明

这是一个完整、可直接运行的 R 项目，覆盖作业的全部 6 道题。

- **`Assignment2.R`**：提交用的 R 脚本，包含第 2、3、6 题的全部代码。
- **`Assignment2_Report.qmd`**：报告源文件。它会运行上面的脚本，导出 **`Assignment2_Report.pdf`**，也就是提交用的 PDF。

## 文件结构

```
ML_Assignment2/
├── Assignment2.R              ← 提交：R 脚本（第 2/3/6 题）
├── Assignment2_Report.qmd     ← 报告源文件（Quarto），导出 PDF
├── Assignment2_Report.pdf     ← 提交：报告（已生成一版，可直接看）
├── 00_install_packages.R      ← 第一次运行前装包
├── data/
│   ├── admission.xls
│   └── Stock_2018.xlsx
├── figures/                   ← 脚本自动保存的图（PNG，可贴进 Word）
├── CLAUDE.md                  ← 给 Claude Code 看的项目说明
└── ML_Assignment2.Rproj       ← 组员用 RStudio 时双击打开
```

## 第一次使用（VS Code）

1. **装 VS Code 扩展**：在扩展里搜 **R**（作者 REditorSupport）并安装；再装 **Quarto** 扩展。
2. **装 Quarto**：到 <https://quarto.org/docs/get-started/> 下载安装包。Quarto 自带 pandoc。
3. **装 LaTeX**：导出 PDF 需要 LaTeX。在 VS Code 终端运行一次 `quarto install tinytex`。
4. **打开项目**：VS Code 里用 *File → Open Folder* 打开 `ML_Assignment2` 文件夹。这一步很重要，这样工作目录才对。
5. **装 R 包**：打开 `00_install_packages.R`，全选后按 `Ctrl+Enter`（Mac 上是 `Cmd+Enter`）运行。

## 日常使用

- **跑代码**：打开 `Assignment2.R`，选中几行按 `Ctrl+Enter` 逐段运行。完整跑一遍大约 2–3 分钟，主要时间花在第 6 题 KNN 选 k、Bagging 和随机森林的交叉验证上。
- **导出 PDF**：在终端运行

  ```
  quarto render Assignment2_Report.qmd
  ```

  也可以打开 `.qmd` 后点右上角的 **Preview** 按钮。
- **改代码要改 `Assignment2.R`**。报告通过 `## ---- 名字 ----` 这种标记读取脚本里的代码块，所以脚本和 PDF 永远一致。不要删这些标记行。
- 报告里的数字（准确率、cp 值等）都是 inline R 代码自动算的，改了代码再 render，数字会跟着变。

## 提交前要做的事

- [ ] 在 `Assignment2_Report.qmd` 顶部填上**组号和组员姓名、学号**（`subtitle`、`author` 两行）。memo 里有一处 `Group \_\_\_` 也要改。
- [ ] 在 `Assignment2.R` 第 3 行填组号。
- [ ] 重新 render，通读一遍 PDF，用自己的话润色解释部分。
- [ ] 检查第 6(b) 的 memo 仍然在**一页之内**。
- [ ] 邮件提交 `Assignment2_Report.pdf` 和 `Assignment2.R`，截止 **10 月 16 日（周五）**。

## 换电脑运行后需要人工核对的地方

所有随机步骤都固定了 `set.seed(2026)`，而且每个模型单独设种子，结果不受模型顺序影响。但不同版本的 R 包（尤其是 randomForest）结果可能有微小差别。

报告里的数字、最佳模型名称和"是否显著"这类判断都是自动生成的。以下几句是写死的文字，render 后请核对：

- **第 5(c) 题**："QDA had the lowest cross-validated accuracy"。
- **第 6 题**："Logistic regression, LDA, bagging and KNN are all within about one CV standard deviation"、最重要的变量是 EPS / P/E / profit margin、memo 里的 "The random forest performed best in cross-validation"。
- **第 4 题**：对 ROC 图的解读是根据作业 PDF 里那张图写的，与代码无关；"AUC ≈ 0.68–0.73" 引用的是第 6 题的结果。

## 第 6 题用了哪些模型（按课件）

| 课件 | 模型 | 作用 |
|---|---|---|
| Lecture 6 | Logistic regression、LDA、QDA | 主要候选 |
| Lecture 8 | Classification tree（按 xerror 剪枝） | 主要候选 |
| Lecture 9 | Bagging（`randomForest`，`mtry = 13`）、Random forest（`mtry = 3`）、KNN（k 用 CV 选） | 主要候选 |
| Lecture 6 | LPM | 只作补充基准，不参与"最佳模型"评选 |
| — | 全部预测上涨 | 朴素基准（68.2%） |

- **选模型的方法：** 先在训练集上用 10 折交叉验证选最佳模型，再在测试集上确认（Lecture 7）。
- **65% 的要求：** 7 个课程模型的 CV 和测试集准确率都在 65% 以上，脚本里的 `course_results` 和 `all_above_65` 会自动检查。
- **没有用的方法：** SVM、Boosting、XGBoost、神经网络课上没有展开教，都没有用。6(c) 只用一句话提到 boosting 可以以后再试。
