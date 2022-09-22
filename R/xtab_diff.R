#' Odds Ratios, Risk Ratios and Cohen's *h* for 2-by-2 Contingency Tables
#'
#' Report with any [`stats::chisq.test()`] or [`stats::fisher.test()`].
#' \cr\cr
#' Note that these are computed with each **column** representing the different
#' groups, and the *first* column representing the treatment group and the
#' *second* column baseline (or control). Effects are given as `treatment /
#' control`. If you wish you use rows as groups you must pass a transposed
#' table, or switch the `x` and `y` arguments.
#'
#'
#' @inheritParams oddsratio_to_d
#' @inheritParams phi
#' @param alternative a character string specifying the alternative hypothesis;
#'   Controls the type of CI returned: `"two.sided"` (two-sided CI; default),
#'   `"greater"` (one-sided CI) or `"less"` (one-sided CI). Partial matching is
#'   allowed (e.g., `"g"`, `"l"`, `"two"`...). See *One-Sided CIs* in
#'   [effectsize_CIs].
#' @param ... Ignored
#'
#' @details
#'
#' # Confidence (Compatibility) Intervals (CIs)
#' For Odds ratios, Risk ratios and Cohen's *h*, confidence intervals are
#' estimated using the standard normal parametric method (see Katz et al., 1978;
#' Szumilas, 2010).
#'
#' @inheritSection effectsize_CIs CIs and Significance Tests
#'
#' @return A data frame with the effect size (`Odds_ratio`, `Risk_ratio`
#'   (possibly with the prefix `log_`), `Cohens_h`) and its CIs (`CI_low` and
#'   `CI_high`).
#'
#' @seealso [phi()] and friends for other effect sizes for contingency tables.
#' @family effect size indices
#'
#'
#' @references
#' - Cohen, J. (1988). Statistical power analysis for the behavioral sciences (2nd Ed.). New York: Routledge.
#' - Katz, D. J. S. M., Baptista, J., Azen, S. P., & Pike, M. C. (1978). Obtaining confidence intervals for the risk ratio in cohort studies. Biometrics, 469-474.
#' - Szumilas, M. (2010). Explaining odds ratios. Journal of the Canadian academy of child and adolescent psychiatry, 19(3), 227.
#'
#' @examples
#' RCT <- matrix(c(71, 50,
#'                 30, 100), nrow = 2)
#' dimnames(RCT) <- list(Diagnosis = c("Sick", "Recovered"),
#'                       Group = c("Treatment", "Control"))
#' RCT # note groups are COLUMNS
#'
#' oddsratio(RCT)
#' oddsratio(RCT, alternative = "greater")
#'
#' riskratio(RCT)
#'
#' cohens_h(RCT)
#'
#'
#'
#' @export
#' @importFrom stats chisq.test qnorm
oddsratio <- function(x, y = NULL, ci = 0.95, alternative = "two.sided", log = FALSE, ...) {
  alternative <- match.arg(alternative, c("two.sided", "less", "greater"))

  if (inherits(x, "htest")) {
    if (grepl("Pearson's Chi-squared", x$method) ||
        grepl("Chi-squared test for given probabilities", x$method)) {
      return(effectsize(x, type = "or", log = log, ci = ci, alternative = alternative))
    } else if (grepl("Fisher's Exact", x$method)) {
      return(effectsize(x, alternative = alternative, ...))
    } else {
      stop("'x' is not a Chi-squared / Fisher's Exact test!", call. = FALSE)
    }
  } else if (inherits(x, "BFBayesFactor")) {
    if (!inherits(x@numerator[[1]], "BFcontingencyTable")) {
      stop("'x' is not a Chi-squared test!", call. = FALSE)
    }
    return(effectsize(x, type = "or", log = log, ci = ci, ...))
  }

  res <- suppressWarnings(stats::chisq.test(x, y))
  Obs <- res$observed

  if (any(c(colSums(Obs), rowSums(Obs)) == 0L)) {
    stop("Cannot have empty rows/columns in the contingency tables.", call. = FALSE)
  }

  if (nrow(Obs) != 2 || ncol(Obs) != 2) {
    stop("Odds ratio only available for 2-by-2 contingency tables", call. = FALSE)
  }

  OR <- (Obs[1, 1] / Obs[2, 1]) /
    (Obs[1, 2] / Obs[2, 2])

  res <- data.frame(Odds_ratio = OR)

  ci_method <- NULL
  if (is.numeric(ci)) {
    stopifnot(length(ci) == 1, ci < 1, ci > 0)
    res$CI <- ci
    ci.level <- if (alternative == "two.sided") ci else 2 * ci - 1

    alpha <- 1 - ci.level

    SE_logodds <- sqrt(sum(1 / Obs))
    Z_logodds <- stats::qnorm(alpha / 2, lower.tail = FALSE)
    confs <- exp(log(OR) + c(-1, 1) * SE_logodds * Z_logodds)

    res$CI_low <- confs[1]
    res$CI_high <- confs[2]

    ci_method <- list(method = "normal")
    if (alternative == "less") {
      res$CI_low <- 0
    } else if (alternative == "greater") {
      res$CI_high <- Inf
    }
  } else {
    alternative <- NULL
  }

  if (log) {
    res[colnames(res) %in% c("Odds_ratio", "CI_low", "CI_high")] <-
      log(res[colnames(res) %in% c("Odds_ratio", "CI_low", "CI_high")])
    colnames(res)[1] <- "log_Odds_ratio"
  }

  class(res) <- c("effectsize_table", "see_effectsize_table", class(res))
  attr(res, "ci") <- ci
  attr(res, "ci_method") <- ci_method
  attr(res, "approximate") <- FALSE
  attr(res, "alternative") <- alternative
  return(res)
}

#' @rdname oddsratio
#' @export
#' @importFrom stats chisq.test qnorm
riskratio <- function(x, y = NULL, ci = 0.95, alternative = "two.sided", log = FALSE, ...) {
  alternative <- match.arg(alternative, c("two.sided", "less", "greater"))

  if (inherits(x, "htest")) {
    if (!(grepl("Pearson's Chi-squared", x$method) ||
          grepl("Chi-squared test for given probabilities", x$method))) {
      stop("'x' is not a Chi-squared test!", call. = FALSE)
    }
    return(effectsize(x, type = "rr", log = log, ci = ci, alternative = alternative))
  } else if (inherits(x, "BFBayesFactor")) {
    if (!inherits(x@numerator[[1]], "BFcontingencyTable")) {
      stop("'x' is not a Chi-squared test!", call. = FALSE)
    }
    return(effectsize(x, type = "rr", log = log, ci = ci, ...))
  }

  res <- suppressWarnings(stats::chisq.test(x, y))
  Obs <- res$observed

  if (any(c(colSums(Obs), rowSums(Obs)) == 0L)) {
    stop("Cannot have empty rows/columns in the contingency tables.", call. = FALSE)
  }

  if (nrow(Obs) != 2 || ncol(Obs) != 2) {
    stop("Risk ratio only available for 2-by-2 contingency tables", call. = FALSE)
  }

  n1 <- sum(Obs[, 1])
  n2 <- sum(Obs[, 2])
  p1 <- Obs[1, 1] / n1
  p2 <- Obs[1, 2] / n2
  RR <- p1 / p2

  res <- data.frame(Risk_ratio = RR)

  ci_method <- NULL
  if (is.numeric(ci)) {
    stopifnot(length(ci) == 1, ci < 1, ci > 0)
    res$CI <- ci
    ci.level <- if (alternative == "two.sided") ci else 2 * ci - 1

    alpha <- 1 - ci.level

    SE_logRR <- sqrt(p1 / ((1 - p1) * n1)) + sqrt(p2 / ((1 - p2) * n2))
    Z_logRR <- stats::qnorm(alpha / 2, lower.tail = FALSE)
    confs <- exp(log(RR) + c(-1, 1) * SE_logRR * Z_logRR)

    res$CI_low <- confs[1]
    res$CI_high <- confs[2]

    ci_method <- list(method = "normal")
    if (alternative == "less") {
      res$CI_low <- 0
    } else if (alternative == "greater") {
      res$CI_high <- Inf
    }
  } else {
    alternative <- NULL
  }

  if (log) {
    res[colnames(res) %in% c("Risk_ratio", "CI_low", "CI_high")] <-
      log(res[colnames(res) %in% c("Risk_ratio", "CI_low", "CI_high")])
    colnames(res)[1] <- "log_Risk_ratio"
  }

  class(res) <- c("effectsize_table", "see_effectsize_table", class(res))
  attr(res, "ci") <- ci
  attr(res, "ci_method") <- ci_method
  attr(res, "approximate") <- FALSE
  attr(res, "alternative") <- alternative
  return(res)
}

#' @rdname oddsratio
#' @export
#' @importFrom stats qnorm
cohens_h <- function(x, y = NULL, ci = 0.95, alternative = "two.sided", ...) {
  alternative <- match.arg(alternative, c("two.sided", "less", "greater"))

  if (inherits(x, "htest")) {
    if (!(grepl("Pearson's Chi-squared", x$method) ||
          grepl("Chi-squared test for given probabilities", x$method))) {
      stop("'x' is not a Chi-squared test!", call. = FALSE)
    }
    return(effectsize(x, type = "cohens_h", ci = ci, alternative = alternative))
  } else if (inherits(x, "BFBayesFactor")) {
    if (!inherits(x@numerator[[1]], "BFcontingencyTable")) {
      stop("'x' is not a Chi-squared test!", call. = FALSE)
    }
    return(effectsize(x, type = "cohens_h", ci = ci, ...))
  }

  res <- suppressWarnings(stats::chisq.test(x, y))
  Obs <- res$observed

  if (any(c(colSums(Obs), rowSums(Obs)) == 0L)) {
    stop("Cannot have empty rows/columns in the contingency tables.", call. = FALSE)
  }

  if (nrow(Obs) != 2 || ncol(Obs) != 2) {
    stop("Cohen's h only available for 2-by-2 contingency tables", call. = FALSE)
  }

  n1 <- sum(Obs[, 1])
  n2 <- sum(Obs[, 2])
  p1 <- Obs[1, 1] / n1
  p2 <- Obs[1, 2] / n2
  H <- 2 * asin(sqrt(p1)) - 2 * asin(sqrt(p2))

  out <- data.frame(Cohens_h = H)

  ci_method <- NULL
  if (is.numeric(ci)) {
    stopifnot(length(ci) == 1, ci < 1, ci > 0)
    out$CI <- ci
    ci.level <- if (alternative == "two.sided") ci else 2 * ci - 1

    alpha <- 1 - ci.level

    se_arcsin <- sqrt(0.25 * (1 / n1 + 1 / n2))
    Zc <- stats::qnorm(alpha / 2, lower.tail = FALSE)
    out$CI_low <- H - Zc * (2 * se_arcsin)
    out$CI_high <- H + Zc * (2 * se_arcsin)

    ci_method <- list(method = "normal")
    if (alternative == "less") {
      out$CI_low <- -pi
    } else if (alternative == "greater") {
      out$CI_high <- pi
    }
  } else {
    alternative <- NULL
  }

  class(out) <- c("effectsize_table", "see_effectsize_table", class(out))
  attr(out, "ci") <- ci
  attr(out, "ci_method") <- ci_method
  attr(out, "approximate") <- FALSE
  attr(out, "alternative") <- alternative
  return(out)
}