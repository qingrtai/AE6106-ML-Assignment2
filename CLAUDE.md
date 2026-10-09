# CLAUDE.md

Group assignment for a Data Analytics & Machine Learning course. It must be done in **R**. Deliverables are a PDF report and the R script, due 16 Oct 2026.

## Files
- `Assignment2.R`: all analysis code (Q2, Q3, Q6). This file is submitted.
- `Assignment2_Report.qmd`: Quarto report. It renders to `Assignment2_Report.pdf`. Q1, Q4 and Q5 are theory and written directly in the .qmd.
- `data/`: `admission.xls` (Q3) and `Stock_2018.xlsx` (Q6). Read with `find_data()`, which looks in `data/` and then the working directory.

## Conventions
- The report reuses the script via `knitr::read_chunk("Assignment2.R")`. Chunk markers look like `## ---- q3d ----`. A qmd chunk with the same label and an empty body runs that code. Keep the markers when editing the script.
- Numbers in the report text are inline R (`` `r ...` ``), not typed by hand.
- Seeds: `set.seed(2026)` before every random step.
- Q6 pre-processing (median imputation, 1%/99% winsorising) is fitted on training data only, via `fit_prep()` and `apply_prep()`.
- Q6 models are in the `model_fns` list. Each element is `function(tr, te)` returning P(Up) for `te`.
- Q6 may only use algorithms taught in the course:
  - logistic regression, LDA and QDA (Lecture 6);
  - classification tree (Lecture 8);
  - bagging, random forest and KNN (Lecture 9).
  LPM (Lecture 6) is a supplementary benchmark only and is excluded from `course_models`. Do not add SVM, boosting, XGBoost or neural networks.
- The lecturer requires accuracy above 65%; `target_acc` and `course_results` check this. The real benchmark is the naive "always Up" rule (68.2%).
- The best model is chosen by 10-fold CV accuracy; the test set is only used to confirm. The test-set loop resets the seed for each model.
- 6(b) must stay on one page of the PDF.

## Commands
- Run the script: `Rscript Assignment2.R` (about 2.5 min).
- Render the report: `quarto render Assignment2_Report.qmd` (about 3.5 min).
