setOldClass("DocumentPage")
setOldClass("Document")
setOldClass(c("PDFToXMLPage", "DocumentPage") )
setOldClass(c("OCRPage", "DocumentPage") )

setOldClass(c("PDFToXMLDocument", "Document") )
setOldClass(c("OCRDocument", "Document") )

#setClass("TextBoundingBox", contains = "data.frame")
#setClass("OCRPageTextBoundingBox", contains = "TextBoundingBox")
#setClass("OCRDocumentTextBoundingBox", contains = "TextBoundingBox")
#setClass("PDFToXMLDocumentTextBoundingBox", contains = "TextBoundingBox")
#setClass("PDFToXMLPageTextBoundingBox", contains = "TextBoundingBox")

setOldClass(c("TextBoundingBox", "data.frame"))
setOldClass(c("OCRPageTextBoundingBox", "TextBoundingBox"))
setOldClass(c("OCRDocumentTextBoundingBox", "TextBoundingBox"))
setOldClass(c("PDFToXMLDocumentTextBoundingBox", "TextBoundingBox"))
setOldClass(c("PDFToXMLPageTextBoundingBox", "TextBoundingBox"))
