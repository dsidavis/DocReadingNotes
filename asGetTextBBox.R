source("ClassDefs.R")

# Define coercion methods that just go straight to getTextBBox.
setAs("Document", "TextBoundingBox", function(from) getTextBBox(from))
setAs("DocumentPage", "TextBoundingBox", function(from) getTextBBox(from))

setGeneric("getTextBBox",
           function(obj, ...)
             standardGeneric("getTextBBox"))

f1 = function(n = 20) {
       structure(data.frame(x = runif(n, 30, 39),
                            y = runif(n, 0, 800),
                            width = runif(n, 3, 30),
                            height = runif(n, 10, 12)) ,
                 class = c("OCRPageTextBoundingBox", "TextBoundingBox"))
}

f2 = function(n = 29) {
          structure(data.frame(x = runif(n, 30, 39) + 10,
                               y = runif(n, 0, 800),
                               width = runif(n, 3, 30),
                               height = runif(n, 10, 12)) ,
                    class = c("PDFToXMLPageTextBoundingBox", "TextBoundingBox"))
      }



setMethod("getTextBBox", "PDFToXMLPage",
          function(obj, ...) {
            cat("getTextBBox(PDFToXMLPage)\n")
            f2()
          })

setMethod("getTextBBox", "OCRPage",
          function(obj, ...) {
            cat("getTextBBox(OCRPage)\n")
            f1()
          })


selectMethod("coerce", c("PDFToXMLPage", "TextBoundingBox"))
selectMethod("coerce", c("OCRPage", "TextBoundingBox"))

pdfPage = structure(1, class = c("PDFToXMLPage", "DocumentPage"))    
ocrPage = structure(2, class = c("OCRPage", "DocumentPage"))

a = as(pdfPage, "TextBoundingBox")
b = as(ocrPage, "TextBoundingBox")

class(a)
class(b)

