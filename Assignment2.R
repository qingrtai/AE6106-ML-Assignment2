# =============================================================================
#  Assignment 2 - Data Analytics and Machine Learning (October 2026)
#  Members: TAI QINGRUI (G2509161H), WAN YUXUAN (G2509146H), FENG YUE (G2509544L)
#
#  R code for Questions 2, 3 and 6. Questions 1, 4 and 5 are theoretical
#  and are answered in the PDF report.
#
#  How to run
#    1. Open the project folder (the folder that contains this file) in
#       VS Code or RStudio, so that it is the working directory.
#    2. Run 00_install_packages.R once.
#    3. Run this whole script. The data files are read from ./data/
#       (or from the working directory) and figures are saved to ./figures/.
#
#  Lines of the form "## ---- name ----" mark code chunks that the Quarto
#  report (Assignment2_Report.qmd) reuses, so the script and the PDF always
#  show the same code and results.
# =============================================================================


## ---- setup ----
suppressPackageStartupMessages({
  library(MASS)          # lda(), qda()  (loaded before dplyr so dplyr::select wins)
  library(readxl)        # read .xls / .xlsx
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(patchwork)     # combine ggplots
  library(rpart)         # decision trees
  library(rpart.plot)    # tree diagrams
  library(class)         # knn()
  library(randomForest)
  library(pROC)          # ROC curves and AUC
})

theme_set(theme_minimal(base_size = 10))
dir.create("figures", showWarnings = FALSE)

# Look for a data file in ./data/ first, then in the working directory
find_data <- function(file) {
  candidates <- c(file.path("data", file), file)
  hit <- candidates[file.exists(candidates)][1]
  if (is.na(hit)) stop("Cannot find ", file, ". Put it in ./data/ or the working directory.")
  hit
}

save_plot <- function(plot, file, width, height) {
  ggsave(file.path("figures", file), plot, width = width, height = height, dpi = 300,
         bg = "white")
}

pct <- function(x, digits = 1) paste0(formatC(100 * x, format = "f", digits = digits), "%")


## ---- banner-q2 ----

# =============================================================================
#  Question 2: confusion matrix of a credit-default model
#  Positive class = Default (+)
# =============================================================================

## ---- q2 ----
TN <- 56000   # predicted non-default, truly non-default
FN <- 400     # predicted non-default, truly default   (missed defaulters)
FP <- 100     # predicted default,     truly non-default (false alarms)
TP <- 700     # predicted default,     truly default

conf_mat <- matrix(c(TN, FP, FN, TP), nrow = 2,
                   dimnames = list(Predicted = c("Non-default (-)", "Default (+)"),
                                   True      = c("Non-default (-)", "Default (+)")))
print(conf_mat)

N <- TN + FN + FP + TP
q2_metrics <- c(
  "Accuracy"                         = (TP + TN) / N,
  "Sensitivity (recall, TPR)"        = TP / (TP + FN),
  "Specificity (TNR)"                = TN / (TN + FP),
  "Precision (PPV)"                  = TP / (TP + FP),
  "Miss rate (FNR = 1 - sens.)"      = FN / (TP + FN),
  "Default rate in data (prevalence)" = (TP + FN) / N,
  "Baseline accuracy: predict all non-default" = (TN + FP) / N,
  "Balanced accuracy"                = (TP / (TP + FN) + TN / (TN + FP)) / 2
)
q2_table <- data.frame(Metric = names(q2_metrics), Value = pct(q2_metrics, 2), row.names = NULL)
print(q2_table)


## ---- banner-q3 ----
# =============================================================================
#  Question 3: Admission data
# =============================================================================

## ---- q3-load ----
adm <- as.data.frame(read_excel(find_data("admission.xls")))
adm$rank  <- factor(adm$rank, levels = 1:4)            # 1 = most prestigious
adm$admit <- factor(adm$admit, levels = c(0, 1), labels = c("Rejected", "Admitted"))
str(adm)
print(summary(adm))

## ---- q3a ----
# (a) Relationships among GRE, GPA and rank
rank_cols <- c("1" = "#0072B2", "2" = "#009E73", "3" = "#E69F00", "4" = "#D55E00")

p_scatter <- ggplot(adm, aes(gpa, gre, colour = rank)) +
  geom_point(position = position_jitter(width = 0.01, height = 4, seed = 1),
             alpha = 0.55, size = 1.5) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, linewidth = 0.9) +
  scale_colour_manual(values = rank_cols, name = "Institution rank") +
  labs(title = "GRE vs GPA (lines: linear fit within each rank)", x = "GPA", y = "GRE") +
  theme(legend.position = "right")

p_gpa <- ggplot(adm, aes(rank, gpa, fill = rank)) +
  geom_boxplot(alpha = 0.7, outlier.size = 0.8) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 2.2, fill = "white") +
  scale_fill_manual(values = rank_cols, guide = "none") +
  labs(title = "GPA by rank (diamond = mean)", x = "Institution rank", y = "GPA")

p_gre <- ggplot(adm, aes(rank, gre, fill = rank)) +
  geom_boxplot(alpha = 0.7, outlier.size = 0.8) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 2.2, fill = "white") +
  scale_fill_manual(values = rank_cols, guide = "none") +
  labs(title = "GRE by rank (diamond = mean)", x = "Institution rank", y = "GRE")

fig_q3a <- p_scatter / (p_gpa | p_gre) + plot_layout(heights = c(1.15, 1))
print(fig_q3a)
save_plot(fig_q3a, "q3a_features.png", width = 8, height = 6.5)

# Correlations that support the picture
q3a_cor <- c(
  "Pearson r(GRE, GPA)"   = cor(adm$gre, adm$gpa),
  "Spearman rho(rank, GPA)" = cor(as.numeric(adm$rank), adm$gpa, method = "spearman"),
  "Spearman rho(rank, GRE)" = cor(as.numeric(adm$rank), adm$gre, method = "spearman")
)
print(round(q3a_cor, 3))
print(cor.test(adm$gre, adm$gpa)$p.value)

## ---- q3b ----
# (b) Average GPA by institution rank
gpa_by_rank <- adm |>
  group_by(rank) |>
  summarise(applicants = n(), mean_GPA = mean(gpa), mean_GRE = mean(gre), .groups = "drop")
print(gpa_by_rank)

## ---- q3c ----
# (c) Percentage of applicants accepted from each rank
admit_by_rank <- adm |>
  group_by(rank) |>
  summarise(applicants = n(),
            admitted   = sum(admit == "Admitted"),
            admit_rate = 100 * mean(admit == "Admitted"),
            .groups = "drop")
print(admit_by_rank)
overall_admit_rate <- mean(adm$admit == "Admitted")

## ---- q3d ----
# (d) Classification tree with GPA, rank and GRE (default settings: cp = 0.01)
set.seed(2026)   # rpart's 10-fold cross-validation (xerror) uses random folds
tree_adm <- rpart(admit ~ gpa + rank + gre, data = adm, method = "class")
print(tree_adm)
print(round(tree_adm$variable.importance, 2))   # total impurity reduction (incl. surrogate splits)

## ---- q3d-plot ----
rpart.plot(tree_adm, type = 2, extra = 106, under = TRUE, faclen = 0,
           box.palette = "BuGn", tweak = 1.05,
           main = "Admission decision tree (number in box = P(Admitted), % = share of applicants)")

## ---- q3e ----
# (e) Complexity-parameter table
printcp(tree_adm)

## ---- q3e-cp ----
cp_tab   <- as.data.frame(tree_adm$cptable)
best_row <- which.min(cp_tab$xerror)
cp_min   <- cp_tab$CP[best_row]                                   # minimum-xerror rule
se_limit <- cp_tab$xerror[best_row] + cp_tab$xstd[best_row]
cp_1se   <- cp_tab$CP[which(cp_tab$xerror <= se_limit)[1]]        # one-standard-error rule
root_err <- mean(adm$admit == "Admitted")                        # root node error = 127/400

cp_tab$train_error_pct <- 100 * root_err * cp_tab$`rel error`
cp_tab$cv_error_pct    <- 100 * root_err * cp_tab$xerror
print(round(cp_tab, 4))
print(c(cp_min = cp_min, cp_1se = cp_1se))

tree_pruned <- prune(tree_adm, cp = cp_min)
print(tree_pruned)

## ---- q3e-plot ----
par(mfrow = c(1, 2), mar = c(4, 4, 6.5, 1))
plotcp(tree_adm)      # top axis = number of leaves; dotted line = min xerror + 1 SE
title("Cross-validated error vs cp", line = 5, cex.main = 0.95)
rpart.plot(tree_pruned, type = 2, extra = 106, under = TRUE, faclen = 0,
           box.palette = "BuGn", main = "Pruned tree (cp with minimum xerror)",
           cex.main = 0.95)
par(mfrow = c(1, 1))

## ---- q3f ----
# (f) Applicant with GPA = 3.8, GRE = 690 from a rank-4 institution
new_applicant <- data.frame(gpa = 3.8, gre = 690, rank = factor(4, levels = 1:4))
q3f <- data.frame(
  tree          = c("Full tree from (d)", "Pruned tree from (e)"),
  P_admitted    = c(predict(tree_adm,    new_applicant, type = "prob")[, "Admitted"],
                    predict(tree_pruned, new_applicant, type = "prob")[, "Admitted"]),
  decision      = c(as.character(predict(tree_adm,    new_applicant, type = "class")),
                    as.character(predict(tree_pruned, new_applicant, type = "class")))
)
print(q3f)


## ---- banner-q6 ----
# =============================================================================
#  Question 6: will a stock's price rise in 2019?  (StockPrice_2018)
# =============================================================================

## ---- q6-load ----
stock_raw <- as.data.frame(read_excel(find_data("Stock_2018.xlsx")))

name_map <- c(
  "Company Name" = "company",          "Revenue Growth" = "rev_growth",
  "EPS" = "eps",                       "Profit Margin" = "profit_margin",
  "Net Profit Margin" = "net_profit_margin", "dividendYield" = "div_yield_1",
  "returnOnAssets" = "roa",            "returnOnEquity" = "roe",
  "debtRatio" = "debt_ratio",          "PE ratio" = "pe_ratio",
  "Dividend Yield" = "div_yield_2",    "Book Value per Share Growth" = "bvps_growth",
  "Debt Growth" = "debt_growth",       "R&D Expense Growth" = "rd_growth",
  "y" = "y")
stopifnot(all(names(stock_raw) %in% names(name_map)))
stock <- stock_raw
names(stock) <- name_map[names(stock_raw)]

features <- setdiff(names(stock), c("company", "y"))
feature_labels <- c(
  rev_growth = "Revenue growth", eps = "EPS", profit_margin = "Profit margin",
  net_profit_margin = "Net profit margin", div_yield_1 = "Dividend yield (1)",
  roa = "Return on assets", roe = "Return on equity", debt_ratio = "Debt ratio",
  pe_ratio = "P/E ratio", div_yield_2 = "Dividend yield (2)",
  bvps_growth = "Book value/share growth", debt_growth = "Debt growth",
  rd_growth = "R&D expense growth")

print(dim(stock))
print(table(stock$y))

## ---- q6-clean ----
# Missing values per feature, and per company
missing_by_feature <- sort(colSums(is.na(stock[features])), decreasing = TRUE)
print(missing_by_feature)
n_missing_row <- rowSums(is.na(stock[features]))
print(table(n_missing_row))

# Companies missing more than half of the 13 ratios carry almost no information
n_before <- nrow(stock)
stock <- stock[n_missing_row <= length(features) / 2, ]
n_dropped <- n_before - nrow(stock)
stock$y <- factor(stock$y, levels = c(0, 1), labels = c("Down", "Up"))
print(c(dropped = n_dropped, kept = nrow(stock)))
print(prop.table(table(stock$y)))

# Pre-processing, learned on training data only (to avoid information leakage):
#   1) fill remaining NAs with the training median
#   2) winsorise each ratio at the training 1st / 99th percentiles,
#      because the raw ratios contain extreme outliers (e.g. ROE above 10^7)
fit_prep <- function(d) {
  q <- function(x, p) quantile(x, p, na.rm = TRUE, names = FALSE)
  list(med = vapply(d[features], median, numeric(1), na.rm = TRUE),
       lo  = vapply(d[features], q, numeric(1), p = 0.01),
       hi  = vapply(d[features], q, numeric(1), p = 0.99))
}
apply_prep <- function(d, prep) {
  for (v in features) {
    x <- d[[v]]
    x[is.na(x)] <- prep$med[[v]]
    d[[v]] <- pmin(pmax(x, prep$lo[[v]]), prep$hi[[v]])
  }
  d$y01 <- as.numeric(d$y == "Up")       # numeric 0/1 response for the LPM
  d
}

# Stratified 70/30 train-test split
set.seed(2026)
train_idx <- unlist(lapply(split(seq_len(nrow(stock)), stock$y),
                           function(i) sample(i, round(0.7 * length(i)))))
train <- stock[train_idx, ]
test  <- stock[-train_idx, ]
print(c(train = nrow(train), test = nrow(test)))

## ---- q6-describe ----
# (b) Descriptive statistics. Medians and IQRs are used because the ratios
# are extremely skewed; the Wilcoxon rank-sum test compares Up vs Down.
desc_stats <- lapply(features, function(v) {
  x <- stock[[v]]; up <- stock$y == "Up"
  data.frame(
    Feature       = feature_labels[[v]],
    Missing       = sum(is.na(x)),
    Median        = median(x, na.rm = TRUE),
    IQR           = IQR(x, na.rm = TRUE),
    Median_Down   = median(x[!up], na.rm = TRUE),
    Median_Up     = median(x[up],  na.rm = TRUE),
    Wilcoxon_p    = wilcox.test(x[up], x[!up])$p.value
  )
}) |> bind_rows()
print(desc_stats)

## ---- q6-desc-plots ----
y_cols <- c(Down = "#D55E00", Up = "#0072B2")

# Display copy only: each ratio clipped at its 5th / 95th percentile so the
# boxes are readable (the models use the 1% / 99% version above)
stock_w <- stock
for (v in features) {
  lim <- quantile(stock_w[[v]], c(0.05, 0.95), na.rm = TRUE)
  stock_w[[v]] <- pmin(pmax(stock_w[[v]], lim[1]), lim[2])
}

p_balance <- ggplot(stock, aes(y, fill = y)) +
  geom_bar(width = 0.6) +
  geom_text(stat = "count", aes(label = paste0(after_stat(count), " (",
            pct(after_stat(count) / sum(after_stat(count))), ")")), vjust = -0.4, size = 3) +
  scale_fill_manual(values = y_cols, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(title = "2019 price direction", x = NULL, y = "Companies")

box_long <- stock_w |>
  dplyr::select(all_of(features), y) |>
  pivot_longer(-y, names_to = "feature", values_to = "value") |>
  filter(!is.na(value)) |>
  mutate(feature = factor(feature_labels[feature], levels = feature_labels))

p_box <- ggplot(box_long, aes(y, value, fill = y)) +
  geom_boxplot(outlier.size = 0.3, outlier.alpha = 0.3, linewidth = 0.3) +
  facet_wrap(~ feature, scales = "free_y", ncol = 5) +
  scale_fill_manual(values = y_cols, guide = "none") +
  labs(title = "Financial ratios by 2019 price direction (clipped at 5th/95th percentiles)",
       x = NULL, y = NULL) +
  theme(strip.text = element_text(size = 7.5), axis.text = element_text(size = 7))

spearman <- cor(stock[features], use = "pairwise.complete.obs", method = "spearman")
dimnames(spearman) <- list(feature_labels[features], feature_labels[features])
cor_long <- as.data.frame(as.table(spearman))
p_cor <- ggplot(cor_long, aes(Var1, Var2, fill = Freq)) +
  geom_tile(colour = "white") +
  geom_text(aes(label = sprintf("%.2f", Freq)), size = 2.1) +
  scale_fill_gradient2(low = "#D55E00", mid = "white", high = "#0072B2",
                       limits = c(-1, 1), name = "Spearman") +
  labs(title = "Rank correlations between ratios", x = NULL, y = NULL) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7),
        axis.text.y = element_text(size = 7))

fig_q6_desc <- (p_balance | p_cor) / p_box + plot_layout(heights = c(1, 1.25), widths = c(1, 2.2))
print(fig_q6_desc)
save_plot(fig_q6_desc, "q6_descriptive.png", width = 10, height = 9)

## ---- q6-models ----
# (a) Candidate models: the seven classifiers taught in the course, plus the
# linear probability model as a supplementary benchmark. Each function is
# trained on `tr` and returns P(Up) for the rows of `te` (both pre-processed).
form <- reformulate(features, response = "y")

model_fns <- list(
  # Lecture 6
  "Logistic regression" = function(tr, te) {
    m <- glm(form, data = tr, family = binomial)
    predict(m, te, type = "response")
  },
  "LDA" = function(tr, te) {
    m <- lda(form, data = tr)
    predict(m, te)$posterior[, "Up"]
  },
  "QDA" = function(tr, te) {
    m <- qda(form, data = tr)
    predict(m, te)$posterior[, "Up"]
  },
  # Lecture 8
  "Classification tree" = function(tr, te) {
    m <- rpart(form, data = tr, method = "class", cp = 0.001)
    best_cp <- m$cptable[which.min(m$cptable[, "xerror"]), "CP"]   # prune by CV error
    predict(prune(m, cp = best_cp), te, type = "prob")[, "Up"]
  },
  # Lecture 9
  "Bagging" = function(tr, te) {
    # bagging = random forest that considers all 13 features at every split
    m <- randomForest(form, data = tr, ntree = 500, mtry = length(features))
    predict(m, te, type = "prob")[, "Up"]
  },
  "Random forest" = function(tr, te) {
    # default mtry = floor(sqrt(13)) = 3 candidate features per split
    m <- randomForest(form, data = tr, ntree = 500)
    predict(m, te, type = "prob")[, "Up"]
  },
  "KNN" = function(tr, te, k = knn_k) {
    centre <- colMeans(tr[features]); spread <- apply(tr[features], 2, sd)
    x_tr <- scale(tr[features], centre, spread)       # put all ratios on the same scale
    x_te <- scale(te[features], centre, spread)
    pred <- knn(x_tr, x_te, cl = tr$y, k = k, prob = TRUE)
    p_win <- attr(pred, "prob")                      # share of votes for the winning class
    ifelse(pred == "Up", p_win, 1 - p_win)
  },
  # Lecture 6, supplementary benchmark only (fitted values can fall outside [0, 1])
  "LPM (benchmark)" = function(tr, te) {
    m <- lm(reformulate(features, response = "y01"), data = tr)
    predict(m, te)
  }
)

course_models <- setdiff(names(model_fns), "LPM (benchmark)")   # candidates for "best"
model_info <- data.frame(
  Model   = c(names(model_fns), "Baseline: always predict Up"),
  Lecture = c("L6", "L6", "L6", "L8", "L9", "L9", "L9", "L6", "-")
)
target_acc <- 0.65                                   # accuracy required by the lecturer

# 10-fold cross-validated accuracy on the training set. The same folds are
# used for every model (same seed), and pre-processing is re-fitted in each fold.
cv_accuracy <- function(fn, data, k_folds = 10, seed = 2026) {
  set.seed(seed)
  folds <- sample(rep(seq_len(k_folds), length.out = nrow(data)))
  vapply(seq_len(k_folds), function(f) {
    tr <- data[folds != f, ]; te <- data[folds == f, ]
    prep <- fit_prep(tr)
    prob <- fn(apply_prep(tr, prep), apply_prep(te, prep))
    mean((prob > 0.5) == (te$y == "Up"))
  }, numeric(1))
}

## ---- q6-knn-tune ----
# Choose k for KNN by 10-fold CV on the training set
k_grid <- seq(1, 101, by = 2)
knn_cv <- vapply(k_grid, function(k)
  mean(cv_accuracy(function(tr, te) model_fns$KNN(tr, te, k = k), train)), numeric(1))
knn_k <- k_grid[which.max(knn_cv)]
print(knn_k)

## ---- q6-cv ----
cv_folds <- lapply(model_fns, cv_accuracy, data = train)
baseline_fn <- function(tr, te) rep(mean(tr$y == "Up"), nrow(te))   # always predict "Up"
cv_folds[["Baseline: always predict Up"]] <- cv_accuracy(baseline_fn, train)

cv_summary <- data.frame(
  Model   = names(cv_folds),
  CV_acc  = vapply(cv_folds, mean, numeric(1)),
  CV_sd   = vapply(cv_folds, sd, numeric(1)),
  row.names = NULL
)
print(cv_summary[order(-cv_summary$CV_acc), ])

## ---- q6-test ----
# Fit every model on the full training set and evaluate on the untouched test set
prep_train <- fit_prep(train)
train_p <- apply_prep(train, prep_train)
test_p  <- apply_prep(test,  prep_train)

# Reset the seed for each model so its result does not depend on list order
test_prob <- lapply(model_fns, function(fn) { set.seed(2026); fn(train_p, test_p) })
test_prob[["Baseline: always predict Up"]] <- baseline_fn(train_p, test_p)

eval_metrics <- function(prob, truth) {
  pred <- prob > 0.5; actual <- truth == "Up"
  auc <- if (length(unique(prob)) > 1) {
    as.numeric(auc(roc(actual, prob, levels = c(FALSE, TRUE), direction = "<", quiet = TRUE)))
  } else 0.5
  c(Test_acc = mean(pred == actual), Sensitivity = mean(pred[actual]),
    Specificity = mean(!pred[!actual]), AUC = auc)
}
test_metrics <- t(vapply(test_prob, eval_metrics, numeric(4), truth = test$y))

results <- cbind(cv_summary, test_metrics[cv_summary$Model, ])
results <- merge(model_info, results, by = "Model", sort = FALSE)
results <- results[order(-results$CV_acc), ]
rownames(results) <- NULL
print(results)

# The best model is the course model with the highest cross-validated accuracy
best_model <- results$Model[results$Model %in% course_models][1]
print(best_model)

# Requirement check: does every course model reach 65% accuracy (CV and test)?
course_results <- results[results$Model %in% course_models, ]
print(c(min_CV_acc = min(course_results$CV_acc), min_test_acc = min(course_results$Test_acc),
        all_above_65 = all(course_results$CV_acc > target_acc & course_results$Test_acc > target_acc)))

## ---- q6-best ----
best_pred <- factor(ifelse(test_prob[[best_model]] > 0.5, "Up", "Down"), levels = c("Down", "Up"))
best_cm <- table(Predicted = best_pred, Actual = test$y)
print(best_cm)

nir      <- mean(test$y == "Up")                     # no-information rate on the test set
best_acc <- mean(best_pred == test$y)
# Is the best model's test accuracy significantly higher than the no-information rate?
best_vs_nir <- binom.test(sum(best_pred == test$y), nrow(test), p = nir, alternative = "greater")
print(c(test_accuracy = best_acc, no_information_rate = nir, p_value = best_vs_nir$p.value))

## ---- q6-seed-check ----
# Robustness: bagging and random forests are random, so a single test accuracy
# depends on the seed. Refit both with 10 different seeds.
seed_check <- lapply(c("Bagging", "Random forest"), function(nm) {
  acc <- vapply(1:10, function(s) {
    set.seed(s)
    mean((model_fns[[nm]](train_p, test_p) > 0.5) == (test$y == "Up"))
  }, numeric(1))
  data.frame(Model = nm, mean = mean(acc), sd = sd(acc), min = min(acc), max = max(acc))
}) |> bind_rows()
print(seed_check)

## ---- q6-importance ----
set.seed(2026)
rf_final <- randomForest(form, data = train_p, ntree = 500, importance = TRUE)
print(rf_final)
importance_df <- data.frame(
  feature = feature_labels[rownames(importance(rf_final))],
  MeanDecreaseAccuracy = importance(rf_final, type = 1)[, 1],
  MeanDecreaseGini     = importance(rf_final, type = 2)[, 1],
  row.names = NULL
) |> arrange(desc(MeanDecreaseAccuracy))
print(importance_df)

## ---- q6-plots ----
acc_df <- results |> mutate(Model = factor(Model, levels = rev(Model)))
acc_long <- acc_df |>
  dplyr::select(Model, `10-fold CV (mean, ±1 sd)` = CV_acc, `Test set` = Test_acc) |>
  pivot_longer(-Model, names_to = "Evaluation", values_to = "Accuracy")

p_acc <- ggplot(acc_long, aes(Accuracy, Model)) +
  geom_vline(xintercept = target_acc, linetype = "dotted", colour = "grey20") +
  geom_vline(xintercept = mean(train$y == "Up"), linetype = "dashed", colour = "grey40") +
  geom_linerange(data = acc_df, aes(xmin = CV_acc - CV_sd, xmax = CV_acc + CV_sd, y = Model),
                 inherit.aes = FALSE, colour = "#9EC5E8", linewidth = 1.2) +
  geom_point(aes(colour = Evaluation, shape = Evaluation), size = 2.4) +
  scale_x_continuous(labels = function(x) paste0(100 * x, "%")) +
  scale_colour_manual(values = c("#5B9BD5", "#D55E00"), name = NULL) +
  scale_shape_manual(values = c(16, 17), name = NULL) +
  labs(title = "Model accuracy",
       subtitle = "Dotted = 65% target; dashed = 'always Up' rule",
       x = "Accuracy", y = NULL) +
  theme(legend.position = "bottom", plot.title.position = "plot")

p_imp <- importance_df |>
  slice_head(n = 8) |>
  ggplot(aes(MeanDecreaseAccuracy, reorder(feature, MeanDecreaseAccuracy))) +
  geom_col(fill = "#0072B2") +
  labs(title = "Random forest: most useful ratios", x = "Mean decrease in accuracy", y = NULL)

roc_list <- lapply(test_prob[course_models], function(p)
  roc(test$y == "Up", p, levels = c(FALSE, TRUE), direction = "<", quiet = TRUE))
p_roc <- ggroc(roc_list, legacy.axes = TRUE, linewidth = 0.6) +
  geom_abline(linetype = "dotted", colour = "grey50") +
  labs(title = "ROC curves on the test set", x = "False positive rate",
       y = "True positive rate", colour = NULL) +
  theme(legend.text = element_text(size = 7))

fig_q6_models <- p_acc / (p_imp | p_roc) + plot_layout(heights = c(1, 1))
print(fig_q6_models)
save_plot(fig_q6_models, "q6_models.png", width = 10, height = 8)

## ---- q6-memo-fig ----
# Share of stocks that rose in 2019, for companies with / without a trait.
# (P/E is recorded as 0 for loss-making firms, so EPS > 0 and P/E > 0 coincide.)
traits <- list(
  "Profitable (EPS > 0)"      = stock$eps > 0,
  "Pays a dividend"           = stock$div_yield_2 > 0,
  "Positive return on equity" = stock$roe > 0,
  "Revenue grew in 2018"      = stock$rev_growth > 0
)
rise_by_trait <- lapply(names(traits), function(t) {
  has <- traits[[t]]; ok <- !is.na(has)
  data.frame(trait = t,
             group = ifelse(has[ok], "Yes", "No"),
             up    = stock$y[ok] == "Up")
}) |>
  bind_rows() |>
  group_by(trait, group) |>
  summarise(rise_rate = mean(up), n = n(), .groups = "drop") |>
  mutate(trait = factor(trait, levels = rev(names(traits))),
         group = factor(group, levels = c("No", "Yes")))   # "Yes" bar drawn on top
print(rise_by_trait)

p_trait <- ggplot(rise_by_trait, aes(rise_rate, trait, fill = group)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  geom_vline(xintercept = mean(stock$y == "Up"), linetype = "dashed", colour = "grey40") +
  geom_text(aes(label = pct(rise_rate, 0)), hjust = -0.15, size = 2.6,
            position = position_dodge(width = 0.75)) +
  scale_x_continuous(labels = function(x) paste0(100 * x, "%"), limits = c(0, 1),
                     expand = expansion(mult = c(0, 0.02))) +
  scale_fill_manual(values = c(Yes = "#0072B2", No = "#BBBBBB"), name = "Company has trait",
                    guide = guide_legend(reverse = TRUE)) +
  labs(title = "Share of stocks that rose in 2019", x = NULL, y = NULL) +
  theme(legend.position = "bottom")

fig_q6_memo <- (p_trait | p_acc) + plot_layout(widths = c(1, 1))
print(fig_q6_memo)
save_plot(fig_q6_memo, "q6_memo.png", width = 10, height = 3.4)