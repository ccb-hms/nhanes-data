
## Run this from top-level directory (Data/ should be a sub-folder)

## Ensure local cache is running. Otherwise skip setting env variable


Sys.setenv(NHANES_TABLE_BASE = "http://127.0.0.1:8080/cdc")

library(nhanesA)
nhanesOptions(use.db = FALSE, log.access = TRUE)
mf <- nhanesManifest()

## Remove the tables we will not download (usually because they are
## large; some others have already been removed by nhanesManifest())

mf <- subset(mf, !startsWith(Table, "PAXMIN"))
mf <- mf[order(mf$Table), ]

FILEROOT <- "./Data"

for (i in seq_len(nrow(mf))) {
    x <- mf$Table[i]
    rawcsv <- sprintf("%s/%s.csv", FILEROOT, x)
    if (!file.exists(rawcsv) && !file.exists(paste0(rawcsv, ".xz"))) {
        cat(x, " -> ", rawcsv, fill = TRUE)
        d <- nhanesFromURL(mf$DataURL[i], translated = FALSE)
        if (is.data.frame(d))
            write.csv(d, file = rawcsv, row.names = FALSE)
        else message("failed: ", x)
    }
}

