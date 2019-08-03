We start with several existing packages
+ ReadPDF/
+ Rtesseract/
+ Rqpdf/
and a command-line  tool
pdftohtml/


The primary goal is to provide a common framework
for manipulating content from PDF and OCR documents
so that we can develop and use intermediate-level functions
that operate on content from either PDF or OCR documents.
These intermediate-level functions are to be written
using representation-neutral approaches so that they
call shared accessor methods and conceptually fundamental functions
shared by PDF and OCR documents.
This goal arises from the observation that we essentially
represent both the PDF and OCR content by "bounding boxes"
which provide the content (characters, text segments or words, textlines or paragraphs)
by their location on the page.  We perform all the computations on this
data.frame of x, y, width, height, content.

The PDF content has additional color and font information that we do not have for
the OCR. However, we can compute the height of the bounding box for OCR content.





GetDocElements/

ReadArticle/
ReadTabularDocs/



The starting point is a document.
We mostly work with individual pages.
However, we do need to work across pages for
+ identifying features common to all pages (headers and footers)
+ collecting content that starts on one pages and continues on the next

+ For an OCR document, we want to be able to separate this into pages



Consider the function margins().
We have this implemented for PDF documents and a page. We will also want it for an OCR page
and document.
We typically want left and right margins. However, the function should also allow
the caller to specify whether we want top and bottom, or left and right, or all margins.
The reasons for not computing all by default are
a) backward compatability, and b) while relatively fast, there are non-trivial
computations to deal with headers and footers and text on the side of the page, e.g.,
rotated text on the right outside of the page providing the URL from where
the document was downloaded.

We want the margins function to be an S4 generic function.
And we want methods that can handle a document or a page, and for each type of origin - PDF and OCR.
Let's consider the simple case where we only want the left and right margins and we will
ignore the text on the side of the page such as watermarks and download URLs.
We recognize that computing the margins in this limited sense really only requires the 
bounding box of the text on the page. In fact, we only need the left-most positions and
the right-most positions.  We can compute these from the text bounding box.
So this helps us define our generic.   
There are at least 2 approaches to this.
1. Define methods for each of PDFtoXMLDocument, OCRDocument, PDFToXMLPage, OCRPage - with appropriate classes
   defined for these.  Each of these can compute the margins() how they like, but we would
   implement them all the same way by computing the bounding box for the text and 
   handing this to a margins() method for a TextBoundingBox object, e.g.,
```
setGeneric("margins", function(obj, ...) standardGeneric("margins"))
setMethod("PDFToXMLPage", function(obj, ...) margins(as(obj, "TextBoundingBox"), ...))
setMethod("OCRImage", function(obj, ...) margins(as(obj, "TextBoundingBox"), ...))
...
```   
Since we are repeating the exact same code for each of the methods by simply coercing the object to
a TextBoundingBox, we can avoid redefining the function using
```
tmp = function(obj, ...) margins(as(obj, "TextBoundingBox"), ...)
setMethod("PDFToXMLPage", tmp)
setMethod("OCRImage", tmp)
```
As usal, this allows us to change the single definition in one place rather than multiple copies of it.

We'll expand on this approach below.

2. An alternative is to do the coercion in the signature using a separate parameter, say bbox with a
   default
   value that performs the coercion, i.e.,
```
setGeneric("margins", function(obj, bbox = as(obj, "TextBoundingBox"), ...) standardGeneric("margins"))
```
We define coercion methods to TextBoundingBox via calls to setAs() for the different classes we anticipate passing 
to margins() as the first argument.
Then, this quite general "generic" function delegates the job of getting the bounding box it needs.
In fact, we don't even really need the generic. We can implement the function as
```
margins = 
function(obj, bbox = as(obj, "TextBoundingBox"), ...) 
{
   c(left = min(bbox$x), right = max(bbox$x + bbox$height))
}
```


What about computing margins using the entire document, i.e. 
either computing the margins per page, or computing the widest margins
across all pages.
Firstly, let's consider what a multi-page TextBoundingBox should be.
We have already arranged it  to be either a list with a TextBoundingBox
for each page, or to collapse that into  a single data frame with the
same columns as per page, but an additional one that identifies the page number
for each row/page element.


One approach is to redefine margins as a generic and not as a function as we just did above.
```
setGeneric("margins", function(obj, bbox = as(obj, "TextBoundingBox"), ...) standardGeneric("margins"))
```

We then define a default method that uses the bbox to do the computations
```
setMethod("margins", c("ANY"),
           function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
               c(left = min(bbox$x), right = max(bbox$x + bbox$height))
           })
```
We may want to make the signature more specific as  `c("ANY", "missing")`
so that we get the default value of bbox.
Or have the same function be defined for the method where bbox is
explicitly a TextBoundingBox, e.g.

```
setMethod("margins", c(bbox = "TextBoundingBox"),
           function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
               c(left = min(bbox$x), right = max(bbox$x + bbox$height))
           })
```
This would allow for calls 
```
margins(, myBBox)
```
Note we have repeated the code for the two methods. We should write this as we do below
by declaring a temporary function and assigning that


We also want to allow for `margins(myBBox)`
so we can define a method as
```
setMethod("margins", c("TextBoundingBox"),
           function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
               c(left = min(obj$x), right = max(obj$x + obj$height))
           })
```
This is not what we want. We are repeating the same computations we
have in the method for "ANY" but we had to change the code to use
obj rather than bbox.
Secondly, if somebody writes a more specific method for 
`margins(, new("MyTextBoundingBoxClass"))`, this will not get invoked
if the bounding box is passed as the first argument.

So instead, we write this so that it calls margin() but with the
first argument in the second plage.
```
setMethod("margins", c(obj = "TextBoundingBox"),
           function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
               margins(, obj)
           })    
```
The call to `margins(new("MyTextBoundingBoxClass"))`
is now mapped to 
`margins(, new("MyTextBoundingBoxClass"))`
and any more specific methods will be invoked.


So our 

```
setGeneric("margins",
           function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
              standardGeneric("margins")   # 
          })

tmp = function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
               c(left = min(bbox$x), right = max(bbox$x + bbox$height), from = "ANY")
           }
setMethod("margins", c("ANY"), tmp)

setMethod("margins", c(bbox = "TextBoundingBox"), tmp)

rm(tmp)

setMethod("margins", c(obj = "TextBoundingBox"),
           function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
               margins(, obj)
           })    
```



To illustrate that our MyTextBoundingBox method would be called, 
let's define that class and a method for it:
```
setOldClass(c("MyTextBoundingBox", "TextBoundingBox", "data.frame"))
setMethod("margins", c(bbox = "MyTextBoundingBox"),
          function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
               c(left = min(bbox$x), right = max(bbox$x + bbox$height), from = "MyTextBoundingBox")
           })
```
We create an instance of this
```
my = structure(data.frame(x = 1:10, y = runif(10, 0, 400), width = rep(21, 10), height = rep(11, 10)),
               class = c("MyTextBoundingBox", "TextBoundingBox", "data.frame"))
```
Now the two calls
```
a = margins(my)
b = margins(, my)    
```
do end up invoking this method as we can see in the value of the `from` element in the result.



Note that we could have avoided repeating the same code in our method for MyTextBoundingBox.
We can define the method to call the inherited method that we are overriding, and then 
to replace/add the new value for the `from` element
```
setMethod("margins", c(bbox = "MyTextBoundingBox"),
          function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
              ans = callNextMethod(, bbox)
              ans["from"] = "MyTextBoundingBox"
              ans
           })
```
Again, this is a good practice. If somebody enhances the inherited method,
we will get the benefit of those changes without changing our code.
This what users expect and also just a "good thing".
Of course, if the changes to the inherited method are incompatible with our expectations of what
will be returned, then we have a problem.
But that is a) less common as hopefully the authors will have backward compatibility as a goal, and 
b) we can always then integrate the code from their original
implementation into  our method.


##
Show 
+ encapsulation
  + writing higher- and intermediate-level functions without knowing about the specific classes
    being operated on
  + write in terms of methods
  + no if(is(x, "className")) or if we do, this is on classes very early/high in the hierarchy
    so just discriminating between concepts (e.g., document versus word), not specific classes
+ reusing code across the different classes
  + use class-specific computations implicitly via methods, not with if-statements.
    + header and footer
	+ section titles
	+ document title 
	   + allowing customization about the type of document
	      + show how can do with 
		     + a different set of prototype section titles,
		     + a method that takes the type of document and returns the protototype titles
			 + introduce new classes for types/families of documents, e.g., WineCatalogs,
			 JournalArticles,  ZoonoticsJournalArticles, QEDArticle (or whatever those red 3 page
			 zoonotics reports are).
+ customisability
+ extensibility



Functions in GetDocElements are the ones to focus on.
See https://docs.google.com/document/d/1oqflsJSBqRZLKrQTkzcCPLNEcHhT7-LY55YF-JSZ_yQ/edit?ts=5ccb9329


