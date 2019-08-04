setGeneric("ff", function(x, y, ...) standardGeneric("ff"))

setMethod("ff", "integer", function(x, y, z = 1, ...) {})
setMethod("ff", "integer", function(x, y, z = 1, ...) {TRUE})
ff(1L)
#[1] TRUE
setMethod("ff", "integer", function(x, y, z = 1, ...) {z})
ff(1L)
#[1] 1
setMethod("ff", "data.frame", function(x, y, z = 10, ...) {nrow(x) + z})
ff(mtcars)
