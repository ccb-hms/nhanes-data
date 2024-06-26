# Copy of NHANES public data and codebook

The repository maintains snapshots of publicly available NHANES data
and documentation. The primary goal is to use these to eventually
populate a database containing the same information in a more
structured manner.

[Note: code below should work, but is not yet tested]

## Requirements

A recent version of R along with the `nhanesA` package, which can be
installed from CRAN. To avoid multiple downloads in case the process
is interrupted and needs to be restarted, local caching can be enabled
using some Bioconductor tools. The following code should set up the
system appropriately.

```r
install.packages(c("httpuv", "BiocManager"), repos = "https://cloud.r-project.org")
BiocManager::install("BiocFileCache")
BiocManager::install_github("cjendres1/nhanes")
BiocManager::install_github("ccb-hms/cachehttp")
```


## Run local caching server

The first step is to start up the caching server. The following code
must be run in a separate R session, which must not terminate.

```r
require(cachehttp)
add_cache("cdc", "https://wwwn.cdc.gov",
          fun = function(x) {
    x <- tolower(x)
    endsWith(x, ".htm") || endsWith(x, ".xpt")
})
s <- start_cache(host = "0.0.0.0", port = 8080,
                 static_path = BiocFileCache::bfccache(BiocFileCache::BiocFileCache()))
## httpuv::stopServer(s) # to stop the httpuv server
```

It is best to keep an eye on the session to see if anything unexpected
is happening, which it sometimes does. In that case, closing the
session and restarting usually works. One thing to look out for is
that the temporary directory does not run out of space.

The advantage of doing it this way is that files will not be
downloaded from the CDC website more than once _unless_ it has been
updated, even if the process is repeated after six months (provided
the cache has not been removed).

## Download and convert to CSV

The following code downloads the XPT files and converts them to CSV
files.

```r
Sys.setenv(NHANES_TABLE_BASE = "http://127.0.0.1:8080/cdc")

library(nhanesA)
nhanesOptions(use.db = FALSE, log.access = TRUE)
mf <- nhanesManifest()

## Remove the tables we will not download (usually because they are
## large; some others have already been removed by nhanesManifest())

mf <- subset(mf, !startsWith(Table, "PAXMIN"))
mf <- mf[order(mf$Table), ]

FILEROOT <- "./Data"

for (x in mf$Table) {
    rawcsv <- sprintf("%s/%s.csv", FILEROOT, x)
    if (!file.exists(rawcsv)) {
        cat(x, " -> ", rawcsv, fill = TRUE)
        d <- nhanes(x, translated = FALSE)
        if (is.data.frame(d))
            write.csv(d, file = rawcsv, row.names = FALSE)
    }
}

for (x in mf$Table) {
    rawcsv <- sprintf("%s/%s.rds", FILEROOT, x)
    if (!file.exists(rawcsv)) {
        cat(x, " -> ", rawcsv, fill = TRUE)
        d <- nhanes(x, translated = FALSE)
        if (is.data.frame(d))
            saveRDS(d, file = rawcsv, compress = "xz")
    }
}


```

## Download documentation files and extract codebooks

TODO


