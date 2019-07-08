`width<-.PDFBoundingBox` = function(x, ..., value)
{
 stopifnot(value >= 0)
  attr(x, "width") <- value
  x
}
