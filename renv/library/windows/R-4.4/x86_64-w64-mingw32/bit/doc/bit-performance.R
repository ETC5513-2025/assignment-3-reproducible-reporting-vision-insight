## ----echo = FALSE, results = "hide", message = FALSE--------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(bit)
library(microbenchmark)
# rmarkdown::render("vignettes/bit-performance.Rmd")
# these are the real settings for the performance vignette
times <- 5
Domain <- c(small=1e3, big=1e6)
Sample <- c(small=1e3, big=1e6)
# these are the settings to keep the cost of CRAN low
#times <- 5
#Domain <- c(small=1e1, big=1e3)
#Sample <- c(small=1e1, big=1e3)

pagebreak <- function() {
  if (knitr::is_latex_output())
    "\\newpage"
  else
    '<div style="page-break-before: always;" />'
}


## ----echo=TRUE, results='asis'------------------------------------------------
a <- 1L
b <- 1e7L
i <- sample(a:b, 1e3)
x <- c(
  R = median(microbenchmark((a:b)[-i], times=times)$time),
  bit = median(microbenchmark(bit_rangediff(c(a, b), i), times=times)$time),
  merge = median(microbenchmark(merge_rangediff(c(a, b), bit_sort(i)), times=times)$time)
)
knitr::kable(as.data.frame(as.list(x / x["R"] * 100)), caption="% of time relative to R", digits=1)

## ----echo=FALSE, results='asis', echo=3:5-------------------------------------
# TODO(r-lib/lintr#773): nolint as a chunk option.
# nolint start: strings_as_factors_linter.
knitr::kable(
  data.frame(
    coin="random 50%",
    often="random 99%",
    rare="random 1%",
    chunk="contiguous chunk of 5%"
  ),
  caption="selection characteristic"
)
# nolint end: strings_as_factors_linter.

## ----echo=FALSE, results='asis'-----------------------------------------------
B <- booltypes[c("logical", "bit", "bitwhich", "which", "ri")]
M <-
  c("size", "[]", "[which]", "[which]<-TRUE", "[]<-logical", "!", "&", "|", "==", "!=", "summary")
G <- list(
  coin = function(n) sample(c(FALSE, TRUE), n, replace=TRUE, prob=c(0.5, 0.5)),
  often = function(n) sample(c(FALSE, TRUE), n, replace=TRUE, prob=c(0.01, 0.99)),
  rare = function(n) sample(c(FALSE, TRUE), n, replace=TRUE, prob=c(0.99, 0.01)),
  chunk = function(n) ri(n %/% 20, 2L * n %/% 20, n)
)
X <- vector("list", length(B) * length(G))
dim(X) <- c(booltype=length(B), data=length(G))
dimnames(X) <- list(booltype=names(B), data=names(G))
tim <- array(NA,
  dim=c(booltype=length(B), metric=length(M), data=length(G)),
  dimnames=list(booltype=names(B), metric=M, data=names(G))
)
for (g in names(G)) {
  x <- G[[g]](Sample[["big"]])
  if (g %in% c("coin", "often", "rare"))
    w <- as.which(as.logical(x))
  for (b in B) {
    if (booltypes[[b]] < 'ri' || (b == 'ri' && g == 'chunk')) {
      X[[b, g]] <- as.booltype(x, b)
      if (g %in% c("coin", "often", "rare") && b %in% c("logical", "bit", "bitwhich")) {
        l <- as.booltype(logical(Sample[["big"]]), b)
        tim[b, "[which]", g] <- median(microbenchmark(l[w], times=times)$time)
        tim[b, "[which]<-TRUE", g] <- median(microbenchmark(l[w] <- TRUE, times=times)$time)
        tim[b, "[]", g] <- median(microbenchmark(l[], times=times)$time)
        tim[b, "[]<-logical", g] <- median(microbenchmark(l[] <- x, times=times)$time)
      }
      tim[b, "size", g] <- object.size(X[[b, g]])
    }
  }
}
for (g in names(G)) {
  for (b in c("logical", "bit", "bitwhich")) {
    x <- X[[b, g]]
    if (!is.null(x)) {
      tim[b, "!", g] <- median(microbenchmark(!x, times=times)$time)
      tim[b, "&", g] <- median(microbenchmark(x & x, times=times)$time)
      tim[b, "|", g] <- median(microbenchmark(x | x, times=times)$time)
      tim[b, "==", g] <- median(microbenchmark(x == x, times=times)$time)
      tim[b, "!=", g] <- median(microbenchmark(x != x, times=times)$time)
      tim[b, "summary", g] <- median(microbenchmark(summary.booltype(x), times=times)$time)
    }
  }
}
i <- match("size", M)
for (b in rev(names(B))) { # logical was in first position, so we do this last!
  tim[b, i, ] <- 100 * tim[b, i, ] / tim["logical", i, ]
  tim[b, -i, ] <- 100 * tim[b, -i, ] / max(tim["logical", -i, ], na.rm=TRUE)
}
#rm(X)

## ----echo=FALSE, fig.cap = "% size and execution time for bit (b) and bitwhich (w) relative to logical (R) in the 'rare' scenario"----
x <- tim[1:3, , "rare"]
m <- rep("", ncol(x))
m <- as.vector(rbind(m, colnames(x), m))
dotchart(x,
  xlim=c(0, max(100, max(x))),
  labels=m,
  pch=c("R", "b", "w"),
  col=c("black", "blue", "red"),
  main="% size and timings in 'rare' scenario",
  sub="l='logical'  b='bit'  w='bitwhich'           % of max(R) in all scenarios"
)

## ----echo=FALSE, fig.cap = "% size and execution time for bit (b) and bitwhich (w) relative to logical (R) in the 'often' scenario"----
x <- tim[1:3, , "often"]
dotchart(x,
  xlim=c(0, max(100, max(x))),
  labels=m,
  pch=c("R", "b", "w"),
  col=c("black", "blue", "red"),
  main="% size and timings in 'often' scenario",
  sub="l='logical'  b='bit'  w='bitwhich'           % of max(R) in all scenarios"
)

## ----echo=FALSE, fig.cap = "% size and execution time for bit (b) and bitwhich (w) relative to logical (R) in the 'coin' scenario"----
x <- tim[1:3, , "coin"]
dotchart(x,
  xlim=c(0, max(100, max(x))),
  labels=m,
  pch=c("R", "b", "w"),
  col=c("black", "blue", "red"),
  main="% size and timings in 'coin' scenario",
  sub="l='logical'  b='bit'  w='bitwhich'           % of max(R) in all scenarios"
)

## ----echo=FALSE, results='asis'-----------------------------------------------
knitr::kable(round(tim[, "size", ], 1), caption="% bytes of logical")

## ----echo=FALSE, results='asis'-----------------------------------------------
knitr::kable(round(tim[, "[]", ], 1), caption="% time of logical")

## ----echo=FALSE, results='asis'-----------------------------------------------
knitr::kable(round(tim[, "[]<-logical", ], 1), caption="% time of logical")

## ----echo=FALSE, results='asis'-----------------------------------------------
knitr::kable(round(tim[, "[which]", ], 1), caption="% time of logical")

## ----echo=FALSE, results='asis'-----------------------------------------------
knitr::kable(round(tim[, "[which]<-TRUE", ], 1), caption="% time of logical")

## ----echo=FALSE, results='asis'-----------------------------------------------
knitr::kable(round(tim[, "!", ], 1), caption="% time for Boolean NOT")

## ----echo=FALSE, results='asis'-----------------------------------------------
knitr::kable(round(tim[, "&", ], 1), caption="% time for Boolean &")

## ----echo=FALSE, results='asis'-----------------------------------------------
knitr::kable(round(tim[, "|", ], 1), caption="% time for Boolean |")

## ----echo=FALSE, results='asis'-----------------------------------------------
knitr::kable(round(tim[, "==", ], 1), caption="% time for Boolean ==")

## ----echo=FALSE, results='asis'-----------------------------------------------
knitr::kable(round(tim[, "!=", ], 1), caption="% time for Boolean !=")

## ----echo=FALSE, results='asis'-----------------------------------------------
knitr::kable(round(tim[, "summary", ][1:2, 1:2], 1), caption="% time for Boolean summary")

## ----echo=FALSE, results='asis'-----------------------------------------------
binaryDomain <- list(
  smallsmall = rep(Domain["small"], 2L),
  smallbig=Domain,
  bigsmall=rev(Domain),
  bigbig=rep(Domain["big"], 2L)
)
binarySample <- list(
  smallsmall = rep(Sample["small"], 2L),
  smallbig=Sample,
  bigsmall=rev(Sample),
  bigbig=rep(Sample["big"], 2L)
)

M <- c("R", "bit", "merge")
G <- c("sort", "sortunique")
D <- c("unsorted", "sorted")

sortM <- vector("list", length(M) * length(G))
dim(sortM) <- c(method=length(M), goal=length(G))
dimnames(sortM) <- list(method=M, goal=G)
sortM[["R", "sort"]] <- sort
sortM[["R", "sortunique"]] <- function(x) sort(unique(x))
sortM[["bit", "sort"]] <- bit_sort
sortM[["bit", "sortunique"]] <- bit_sort_unique

timsort <- array(NA_integer_,
  dim=c(M=2, G=length(G), D=length(D), N=length(Domain)),
  dimnames=list(M=M[1:2], G=G, D=D, N=names(Domain))
)
for (n in names(Domain)) {
  x <- sample(Domain[[n]], Sample[[n]], replace = TRUE)
  d <- "unsorted"
  for (m in c("R", "bit")) {
    for (g in G) {
      timsort[m, g, d, n] <- median(microbenchmark(sortM[[m, g]](x), times=times)$time)
    }
  }
  x <- bit_sort(x)
  d <- "sorted"
  for (m in 1:2) {
    for (g in G) {
      timsort[m, g, d, n] <- median(microbenchmark(sortM[[m, g]](x), times=times)$time)
    }
  }
}


binaryU <-
  c("match", "in", "notin", "union", "intersect", "setdiff", "symdiff", "setequal", "setearly")
binaryM <- vector("list", length(M) * length(binaryU))
dim(binaryM) <- c(method=length(M), task=length(binaryU))
dimnames(binaryM) <- list(method=M, task=binaryU)
binaryM[["R", "match"]] <- match
binaryM[["merge", "match"]] <- merge_match

binaryM[["R", "in"]] <- get("%in%")
binaryM[["bit", "in"]] <- bit_in
binaryM[["merge", "in"]] <- merge_in

binaryM[["R", "notin"]] <- function(x, y) !(x %in% y)
binaryM[["bit", "notin"]] <- function(x, y) !bit_in(x, y)
binaryM[["merge", "notin"]] <- merge_notin

binaryM[["R", "union"]] <- union
binaryM[["bit", "union"]] <- bit_union
binaryM[["merge", "union"]] <- merge_union

binaryM[["R", "intersect"]] <- intersect
binaryM[["bit", "intersect"]] <- bit_intersect
binaryM[["merge", "intersect"]] <- merge_intersect

binaryM[["R", "setdiff"]] <- setdiff
binaryM[["bit", "setdiff"]] <- bit_setdiff
binaryM[["merge", "setdiff"]] <- merge_setdiff

binaryM[["R", "symdiff"]] <- function(x, y) union(setdiff(x, y), setdiff(y, x))
binaryM[["bit", "symdiff"]] <- bit_symdiff
binaryM[["merge", "symdiff"]] <- merge_symdiff

binaryM[["R", "setequal"]] <-
  function(x, y) setequal(x, x) # we compare x to x which avoids early termination
binaryM[["bit", "setequal"]] <- function(x, y) bit_setequal(x, x)
binaryM[["merge", "setequal"]] <- function(x, y) merge_setequal(x, x)

binaryM[["R", "setearly"]] <-
  function(x, y) setequal(x, y) # we compare x to x which avoids early termination
binaryM[["bit", "setearly"]] <- function(x, y) bit_setequal(x, y)
binaryM[["merge", "setearly"]] <- function(x, y) merge_setequal(x, y)

unaryU <- c("unique", "duplicated", "anyDuplicated", "sumDuplicated")
unaryM <- vector("list", length(M) * length(unaryU))
dim(unaryM) <- c(method=length(M), task=length(unaryU))
dimnames(unaryM) <- list(method=M, task=unaryU)
unaryM[["R", "unique"]] <- unique
unaryM[["bit", "unique"]] <- bit_unique
unaryM[["merge", "unique"]] <- merge_unique
unaryM[["R", "duplicated"]] <- duplicated
unaryM[["bit", "duplicated"]] <- bit_duplicated
unaryM[["merge", "duplicated"]] <- merge_duplicated
unaryM[["R", "anyDuplicated"]] <- anyDuplicated
unaryM[["bit", "anyDuplicated"]] <- bit_anyDuplicated
unaryM[["merge", "anyDuplicated"]] <- merge_anyDuplicated
unaryM[["R", "sumDuplicated"]] <- function(x) sum(duplicated(x))
unaryM[["bit", "sumDuplicated"]] <- bit_sumDuplicated
unaryM[["merge", "sumDuplicated"]] <- merge_sumDuplicated

tim <- array(NA_integer_,
  dim=c(M=length(M), U=length(unaryU) + length(binaryU), N=length(binaryDomain), D=length(D)),
  dimnames=list(M=M, U=c(unaryU, binaryU), N=names(binaryDomain), D=D)
)

for (n in names(binaryDomain)) {
  xnam <- names(binaryDomain[[n]])[1]
  ynam <- names(binaryDomain[[n]])[2]
  x <- sample(binaryDomain[[n]][1], binarySample[[n]][1], replace = FALSE)
  y <- sample(binaryDomain[[n]][2], binarySample[[n]][2], replace = FALSE)
  d <- "unsorted"
  if (length(x) == length(y)) {
    for (u in unaryU) {
      for (m in setdiff(M, "merge")) {
        f <- unaryM[[m, u]]
        if (!is.null(f))
          tim[m, u, n, d] <- median(microbenchmark(f(x), times=times)$time)
      }
    }
  }
  for (u in binaryU) {
    for (m in setdiff(M, "merge")) {
      f <- binaryM[[m, u]]
      if (!is.null(f))
        tim[m, u, n, d] <- median(microbenchmark(f(x, y), times=times)$time)
    }
  }
  x <- bit_sort(x)
  y <- bit_sort(y)
  d <- "sorted"
  if (length(x) == length(y)) {
    for (u in unaryU) {
      for (m in M) {
        f <- unaryM[[m, u]]
        if (!is.null(f)) {
          tim[m, u, n, d] <- median(microbenchmark(f(x), times=times)$time)
          # now plug-in measures for unsorted merge
          if (m == "merge") {
            tim["merge", u, n, "unsorted"] <-
              timsort["bit", "sort", "unsorted", xnam] +  tim["merge", u, n, "sorted"]
          }
        }
      }
    }
  }
  for (u in binaryU) {
    for (m in M) {
      f <- binaryM[[m, u]]
      if (!is.null(f)) {
        tim[m, u, n, d] <- median(microbenchmark(f(x, y), times=times)$time)
        # now plug-in measures for unsorted merge
        if (m == "merge") {
          tim["merge", u, n, "unsorted"] =
            timsort["bit", "sort", "unsorted", xnam] +
            timsort["bit", "sort", "unsorted", ynam] +
            tim["merge", u, n, "sorted"]
        }
      }
    }
  }
}

## ----echo=FALSE, fig.cap = "Execution time for R (R) and bit (b)"-------------
y <- timsort[, , , "big"]
y <- 100 * y / max(y["R", , ], na.rm=TRUE)
oldpar <- par(mfrow=c(2, 1), mar=c(5, 8, 2, 1))
x <- y[, , "unsorted"]
dotchart(x,
  xlim=c(0, max(100, max(y))),
  labels="",
  pch=c("R", "b"),
  xlab="execution time",
  main="unsorted",
  col=c("red", "blue")
)
x <- y[, , "sorted"]
dotchart(x,
  xlim=c(0, max(100, max(y))),
  labels="",
  pch=c("R", "b"),
  xlab="execution time",
  main="sorted",
  col=c("red", "blue")
)
par(oldpar)

## ----echo=FALSE, results='hide'-----------------------------------------------
tim2 <- tim
for (n in names(binaryDomain)) {
  for (d in D) {
    tim2[, , n, d] <- 100 * tim[, , n, d] / max(tim["R", , n, d], na.rm=TRUE)
  }
}

## ----echo=FALSE, fig.cap = "Execution time for R, bit and merge relative to most expensive R in 'unsorted bigbig' scenario"----
y <- tim2[, , "bigbig", ]
y <- 100 * y / max(y["R", , ], na.rm=TRUE)
x <- y[, , "unsorted"]
m <- rep("", ncol(x))
m <- as.vector(rbind(m, colnames(x), m))
dotchart(x,
  xlim=c(0, max(100, max(y, na.rm=TRUE))),
  labels=m,
  pch=c("R", "b", "m"),
  col=c("red", "blue", "black"),
  main="Timings in 'unsorted bigbig' scenario",
  sub="R='hash'   b='bit'   m='merge'"
)

## ----echo=FALSE, fig.cap = "Execution time for R, bit and merge in 'sorted bigbig' scenario"----
x <- y[, , "sorted"]
dotchart(x,
  xlim=c(0, max(y, na.rm=TRUE)),
  labels=m,
  pch=c("R", "b", "m"),
  col=c("red", "blue", "black"),
  main="Timings in 'sorted bigbig' scenario",
  sub="R='hash'   b='bit'   m='merge'"
)

## ----echo=FALSE, results='asis'-----------------------------------------------
x <- 100 * timsort["bit", , , ] / timsort["R", , , ]
s <- "sorted"
knitr::kable(x[, s, ], caption=paste(s, "data relative to R's sort"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, s, ], caption=paste(s, "data relative to R's sort"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
f <- function(u) {
  n <- c("smallsmall", "bigbig")
  x <- tim[c("bit", "merge", "merge"), u, n, ]
  dimnames(x)$M[3] <- "sort"
  dimnames(x)$N <- c("small", "big")
  x["sort", , "unsorted"] <- timsort["bit", "sort", "unsorted", ]
  x["sort", , "sorted"] <- 0
  for (m in dimnames(x)$M) {
    x[m, , ] <- x[m, , ] / tim["R", u, n, ] * 100
  }
  x
}
x <- f("unique")
s <- "sorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
x <- f("duplicated")
s <- "sorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
x <- f("anyDuplicated")
s <- "sorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
x <- f("sumDuplicated")
s <- "sorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
f <- function(u) {
  x <- tim[c("bit", "merge", "merge"), u, , ]
  dimnames(x)$M[3] <- "sort"
  s <- timsort["bit", "sort", "unsorted", ]
  x["sort", , "unsorted"] <- rep(s, c(2, 2)) + c(s, s)
  x["sort", , "sorted"] <- 0
  for (m in dimnames(x)$M) {
    x[m, , ] <- x[m, , ] / tim["R", u, , ] * 100
  }
  x
}
x <- f("match")
s <- "sorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
x <- f("in")
s <- "sorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
x <- f("notin")
s <- "sorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
x <- f("union")
s <- "sorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
x <- f("intersect")
s <- "sorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
x <- f("setdiff")
s <- "sorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
x <- f("symdiff")
s <- "sorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
x <- f("setequal")
s <- "sorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
x <- f("setearly")
s <- "sorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

## ----echo=FALSE, results='asis'-----------------------------------------------
s <- "unsorted"
knitr::kable(x[, , s], caption=paste(s, "data relative to R"), digits=1)

