
# Dociface Package


For technical reasons to do with generics and methods, mostly in S4 but also to some extent S3,
we introduce a "virtual" package named Dociface. The name is for Documents interface.

The idea is to define some core/intrinsic functions that should apply to a document.
The concept of a document in this package is a text document, but could extend to a diagram/figure.
We are thinking about text that is organized by position on the page.
The target documents are PDF and scanned/OCRed documents.

We define 
+ getNumPages
+ getPages

We hope to be able to move some of the functions in GetDocElements
to this package. These are functions that can be entirely expressed
in terms of other functions defined on a generic Document object.
These other functions will be implemented via methods that
other packages provide that are specific to the format of the documents
that package processes.

Consider a general margins.Document
```
margins.Document = 
function(page, asDataFrame = TRUE, ...)        
{
    ans = lapply(getPages(page), margins)
    if(asDataFrame)
        as.data.frame(do.call(rbind, ans))
    else
        ans
}
```
This takes a Document and computes the margins for all pages, returning
the result as a list or a data frame.
This function calls getPages() and margings(). getPages() is implemented very differently in ReadPDF
and Rtesseract but returns a list of DocumentPage objects.


This is a method for margins(). This generic should be defined in Dociface.




In fact, GetDocElements may become this package
and not sit down-stream of ReadPDF and Rtesseract. Instead, these 2 packages
import Dociface a

getNumPages() is a trivial example of where this package provides a general implementation
that other packages inherit and don't have to provide their own method.
We define this as the length of the result of getPages(), i.e.,
```
setMethod("getNumPages", "Document",
          function(doc, ...)
            length(getPages(doc)))
```
While not necessarily optimal, this works for all documents.
The ReadPDF package defines this as the length of an XPath query
```
length(getNodeSet(doc, "//page"))
```
and this is less overhead of actually creating the list of page objects.
