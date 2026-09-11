#!/usr/bin/env Rscript
# Unit tests for `mytools sort`. No bedtools required, runs in seconds.

get_script_path <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
  normalizePath(file_arg)
}

repo_root <- dirname(dirname(get_script_path()))
mytools <- file.path(repo_root, "mytools")

pass <- 0L; fail <- 0L

check <- function(name, ok) {
  if (isTRUE(ok)) {
    cat(sprintf("ok   %s\n", name)); pass <<- pass + 1L
  } else {
    cat(sprintf("FAIL %s\n", name)); fail <<- fail + 1L
  }
}

run_sort <- function(input_text) {
  tmp <- tempfile(); on.exit(unlink(tmp))
  writeLines(input_text, tmp)
  out <- suppressWarnings(system2(mytools, c("sort", "-i", tmp), stdout = TRUE, stderr = TRUE))
  rc <- attr(out, "status"); if (is.null(rc)) rc <- 0L
  list(out = out, rc = rc)
}

# chrom is sorted lexicographically: chr1 before chr17 before chr7
r <- run_sort(c("chr7\t10\t20", "chr17\t10\t20", "chr1\t10\t20"))
check("lexicographic chrom order (chr1, chr17, chr7)",
      r$rc == 0 && identical(r$out, c("chr1\t10\t20", "chr17\t10\t20", "chr7\t10\t20")))

# start > end is a data error: exit 1
r <- run_sort("chr1\t100\t50")
check("start > end exits 1", r$rc == 1)

# non-integer coordinate is a data error: exit 1
r <- run_sort("chr1\tfoo\t50")
check("non-integer coordinate exits 1", r$rc == 1)

# missing input file exits 2
out <- suppressWarnings(system2(mytools, c("sort", "-i", "/no/such/file"), stdout = TRUE, stderr = TRUE))
rc <- attr(out, "status"); if (is.null(rc)) rc <- 0L
check("missing input file exits 2", rc == 2)

cat("---\n")
cat(sprintf("%d passed, %d failed\n", pass, fail))
quit(status = if (fail == 0) 0 else 1, save = "no")
