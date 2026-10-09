# Run this once to install every package used by Assignment2.R and the report.

pkgs <- c(
  "readxl", "dplyr", "tidyr", "ggplot2", "patchwork",   # data and graphics
  "rpart", "rpart.plot", "MASS", "class",               # trees, LDA/QDA, KNN
  "randomForest", "pROC",                               # random forest, ROC/AUC
  "knitr", "rmarkdown",                                 # needed by Quarto to run R code
  "languageserver"                                      # VS Code R extension (autocomplete)
)

missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing) > 0) {
  install.packages(missing, repos = "https://cloud.r-project.org")
} else {
  message("All packages are already installed.")
}
