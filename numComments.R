# % comments
sapply(list.files(pattern = "\\.R$"), function(x) sum(grepl("#", ll <- readLines(x)))/length(ll[trimws(ll) != ""]))

# Num lines of actual code.
sum(sapply(list.files(pattern = "\\.R$"), function(x) length(grep("(^[[:space:]]*#|^[[:space:]]*$)", readLines(x), invert = TRUE, value = TRUE))))
