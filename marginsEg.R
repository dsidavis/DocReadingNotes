source("ClassDefs.R")

setAs("OCRPage", "TextBoundingBox",
      function(from) {
          print(class(from))
          n = 20
          structure(data.frame(x = runif(n, 30, 39), y = runif(n, 0, 800), width = runif(n, 3, 30), height = runif(n, 10, 12)) ,
                    class = c("OCRPageTextBoundingBox", "TextBoundingBox"))
      })

setAs("PDFToXMLPage", "TextBoundingBox",
      function(from) {
          print(class(from))
          n = 29
          structure(data.frame(x = runif(n, 30, 39) + 10, y = runif(n, 0, 800), width = runif(n, 3, 30), height = runif(n, 10, 12)) ,
                    class = c("PDFToXMLPageTextBoundingBox", "TextBoundingBox"))
      })

setGeneric("margins",
           function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
              standardGeneric("margins")   # 
          })

tmp = function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
               c(left = min(bbox$x), right = max(bbox$x + bbox$width), from = "ANY")
           }
setMethod("margins", c("ANY"), tmp)

setMethod("margins", c(bbox = "TextBoundingBox"), tmp)

setMethod("margins", c(obj = "TextBoundingBox"),
           function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
               margins(, obj)
           })    


setOldClass(c("MyTextBoundingBox", "TextBoundingBox", "data.frame"))
setMethod("margins", c(bbox = "MyTextBoundingBox"),
          function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
              # Could have copied the computations from the original method
              # c(left = min(bbox$x), right = max(bbox$x + bbox$height), from = "MyTextBoundingBox")
              # but we don't. We use callNextMethod().
              ans = callNextMethod(, bbox)
              ans["from"] = "MyTextBoundingBox"
              ans
           })

pdfPage = structure(1, class = c("PDFToXMLPage", "DocumentPage"))    
ocrPage = structure(2, class = c("OCRPage", "DocumentPage"))

if(FALSE) {
    margins(pdfPage)
    margins(ocrPage)

    bb.pdf = as(ocrPage, "TextBoundingBox")
    bb.ocr = as(ocrPage, "TextBoundingBox")
    # creating this separately from the call to margins() to illustrate the
    # printing of the class takes place in the coercion and not in margins().
    margins(, bb.pdf)
    margins(, bb.ocr)

    margins(bb.pdf)

    my = structure(data.frame(x = 1:10, y = runif(10, 0, 400), width = rep(21, 10), height = rep(11, 10)),
               class = c("MyTextBoundingBox", "TextBoundingBox", "data.frame"))
    a = margins(my)
    b = margins(, my)

    selectMethod("margins", c("ANY", bbox = "MyTextBoundingBox"))
}



if(FALSE) {
margins = 
function(obj, bbox = as(obj, "TextBoundingBox"), ...) 
{
   c(left = min(bbox$x), right = max(bbox$x + bbox$height))
}

    margins(pdfPage)
    margins(ocrPage)
}
