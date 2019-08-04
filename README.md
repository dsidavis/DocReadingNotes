# Other Documents
+ [This](README.md)
+ [getTitle](Title.md)
+ [Analyzing code in functions to identify abstractions and representation-specific implementations](README2.md)

# Strategies for Integrating OCR and PDF Document Manipulation Code.

<!--  
  Show how to reuse computations across OCR and PDF.
  Implement
    footer
	  +  example with just page number.
	number of columns.
	  + combine by line
	  + find gaps in text on same line where gap is too large
	    and where it occurs in many lines at the same place.
	section titles.
	  + get a different set of prototype section titles based on the class of the
         document.
	  + find on centered line by self
	  + find left aligned in different font - PDF
	      if tesseract could give us back isBold, we could use that.
		  
    plot the page from a page, from a bounding box.		  
	   get the text
	   get the lines/shapes
	   
	   highlight specific points with circles around them.
	   
-->


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



# Object-Oriented Programming
## Goals
To show
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
+ extensibility
+ customisability


### margins() function
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
As usual, this allows us to change the single definition in one place rather than multiple copies of it.

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
   c(left = min(bbox$x), right = max(bbox$x + bbox$width))
}
```

 
What about computing margins using the entire document, i.e. 
either computing the margins per page, or computing the widest margins
across all pages.
Suppose we pass a Document object to our margins function above.
If there is a method for coercing a Document object to a TextBoundingBox,
then this will work, or at least give an answer, even if it is not what we expected.

Let's consider what a multi-page TextBoundingBox should be.
In earlier versions of the ReadPDF package, we arranged it  to be either 
+ a list with a separate data.frame/TextBoundingBox for each page, or 
+ to collapse that list into a single data frame with the
   same x, y, width, height columns as per page, but an 
   additional one that identifies the page number for each row/page element.
Consider the first of these. The resulting list is not a TextBoundingBox,
but a list of TextBoundingBox objects. 
So our implementation of the margins() function above will fail - the resulting
bbox object will not have an x or  width element. (The elements of the list will
have these sub-elements named x and width, but not the top-level itself.)

Of course, if our coercion method for a Document created the second type of
object, i.e. a combination of the data.frame from all of the pages
with the additional column identifying the page,
then our margins() function would not give an error.
The data.frame would be a TextBoundingBox, or at least have the x and width elements.
The code would compute the minimum x and maximum right-most position.
This might be what we wanted.  However, it doesn't allow us to ask 
for the margins by page.

Also, see below in [Encapsulation](#EncapsulationAnchor) for the problem
of handling different representations of the TextBoundingBox as a data.frame
or  matrix, and with different ways to represent the location (x, y, width, height
versus x0, y0, x1, y1 for the two points of the enclosing rectangle.)

So we need a little more flexibility and ability to say what we want to happen
in different situations, while writing the minimum amount of code, and reusing as much
code as possible.


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
so that we know we are getting the default value of bbox.
Or we can have the same function be defined for the method where bbox is
explicitly passed as a TextBoundingBox, e.g.
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
by declaring a temporary function (`tmp`) and assigning that


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


### Inheritance of Methods

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
Also, if somebody defines a method for a class between MyTextBoundingBox
and TextBoundingBox, we would inherit this in the callNextMethod().
For example, if we had defined the margins() method for data.frame and not
TextBoundingBox, then callNextMethod() would have dispatched to that data.frame method.
However, if we or somebody else then added a method for TextBoundingBox, our
callNextMethod() would find that.  Again, there is no change to the existing code
and definitions, just the separate addition of a new method
This what users expect and also just a "good thing".

Of course, if the changes to the inherited method are incompatible with our expectations of what
will be returned, then we have a problem.
But that is a) less common as hopefully the authors will have backward compatibility as a goal, and 
b) we can always then integrate the code from their original
implementation into  our method.


#### Encapsulation [#EncapsulationAnchor]

Note that only one of our methods actually accessed columns in the data.frame, i.e.,
```
 c(left = min(bbox$x), right = max(bbox$x + bbox$height))
```
The other methods avoided using the representation.
This is encapsulation. The goal is to allow us (the authors) to change the representation
of the object without changing the API for users of the object.
If we move to a matrix representation, the code above will break as the $ operator
won't function.
So if we want, we might abstract this further to provide a function
to access the left position and the right position of the elements.
Or the left and the width.
```
setGeneric("left", function(x, ...) standardGeneric("left"))
setGeneric("width", function(x, ...) standardGeneric("width"))
setGeneric("right", function(x, ...) standardGeneric("right"))
setGeneric("height", function(x, ...) standardGeneric("height"))

setMethod("left", "TextBoundingBox", function(x, ...) x$x)
setMethod("width", "TextBoundingBox", function(x, ...) x$width)
setMethod("right", "TextBoundingBox", function(x, ...) left(x) + width(x))
```

So we can now write our tmp function above as
```
tmp = function(obj, bbox = as(obj, "TextBoundingBox"), ...) {
               c(left = min(left(bbox)), right = max(right(bbox)), from = "ANY")
           }
```
This is slightly slower because of the extra function calls and method dispatch.
However it is more flexible. Firstly, we can define methods for other representations,
e.g. our matrix representation.
```
setMethod("left", "MatrixTextBoundingBox", function(x, ...) x[, "x"])
setMethod("width", "MatrixTextBoundingBox", function(x, ...) x[, "width"])
```
Again, note that right is written in terms of accessors rather than knowledge
of the representation of x and the TextBoundingBox. 
This means the right() method  will continue to do "the right thing" 
for sub-classes which provide methods for left() and width().

Of course, these two new MatrixTextBoundingBox methods suggest we could have handled both data.frame and matrices with the same column names by using the `x[, "width"]`
rather than `x$width` subsetting operation. And that is what we should have done.
But there is another matrix-representation, say MatrixPointsTextBoundingBox, 
for our bounding-box that we use
that give the location as the start and end position as x0, y0, and x1, y1.
There, we would define
```
setMethod("left", "MatrixPointsTextBoundingBox", function(x, ...) x$x0)
setMethod("right", "MatrixPointsTextBoundingBox", function(x, ...) x$x1)
setMethod("width", "MatrixPointsTextBoundingBox", function(x, ...) x$x1 - x$x0)
setMethod("height", "MatrixPointsTextBoundingBox", function(x, ...) x$y1 - x$y0)
setMethod("top", "MatrixPointsTextBoundingBox", function(x, ...) x$y0)
setMethod("bottom", "MatrixPointsTextBoundingBox", function(x, ...) x$y1)
```
Note that y0 and y1 here are assumed to be increasing from the top-left and y1
is greater than y0. If this were not the case,  we might write our height() method
as
```
setMethod("height", "MatrixPointsTextBoundingBox", function(x, ...) abs(x$y1 - x$y0))
```
By writing our function `tmp` using these abstractions, we avoid any assumption
of the  representation and, with methods for the abstractions,
our `tmp` function can end up calling methods for various different classes of
inputs without it needing to know about them. `tmp` is therefore much more flexible
and can invoke newly defined methods after it was defined.
There are no if() statements that check the class of the arguments.



Note that we have only worked on the limited version
of margins that a) works on a single page, b) ignores the headers and footers
and other extraneous text.


### Flexibility in the Default Value for `bbox`
<!-- Check in marginsEg.R -->
Should we use `as(obj, "TextBoundingBox")` as the default value for
our `bbox` parameter in our `margins` method, or would 
```
bbox = getTextBBox(obj)
```
be better.
I like the ability to declare "get me an object of this class" via as().
It doesn't require us to know the verb (function name) to do this.
However, it does mean that we cannot pass any additional parameters in the coercion, since
`as()` can never admit/accept any other parameters.
Alternatively, we can add parameters to getTextBBox() to control
whether it returns  a data.frame,  matrix or list, or we can even specify the
class of the return object.
Furthermore, we can provide methods for getTextBBox() to handle different classes of inputs.


The way forward is to define methods for getTextBBox() with appropriate
default values and then to have as() methods that call getTextBBox()
and use these defaults. This way we have the "best" of both worlds - 
simple coercion but also have more control over the "coercion"
by calling getTextBBox() directly.
See [asGetTextBBox.R](asGetTextBBox.R) for code that verifies this.

We start with as() methods that call getTextBBox().
We could define this very generally for ANY object, i.e.,
```
setAs("ANY", "TextBoundingBox", function(from) getTextBBox(from))
```
This seems too general and licentious. This allows 
`as(1, "TextBoundBox")` and `as("myFileName", "TextBoundBox")`
to be passed to getTextBBox.

Instead, we define coercion methods for the
two high-level virtual classes Document and DocumentPage
```
setAs("Document", "TextBoundingBox", function(from) getTextBBox(from))
setAs("DocumentPage", "TextBoundingBox", function(from) getTextBBox(from))
```

Next, we define a generic for getTextBBox:
```
setGeneric("getTextBBox",
           function(obj, ...)
             standardGeneric("getTextBBox"))
```
And then we define methods for getTextBBox()
for handling PDF and OCR pages
```
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
```
We have hidden the actual code for these methods in
functions named f1() and f2(). The actual code is not the focus
here, but the dispatch.

So now we can check the dispatch is correct.
We can query the method that will be selected with
```
selectMethod("coerce", c("PDFToXMLPage", "TextBoundingBox"))
selectMethod("coerce", c("OCRPage", "TextBoundingBox"))
```

And we can check that it works in practice also
```
pdfPage = structure(1, class = c("PDFToXMLPage", "DocumentPage"))    
ocrPage = structure(2, class = c("OCRPage", "DocumentPage"))

a = as(pdfPage, "TextBoundingBox")
b = as(ocrPage, "TextBoundingBox")
```


There is nothing stopping a method for getTextBBox() (or `as(, "TextBoundingBox")`)
from returning an pbject that is not a TextBoundingBox.
It can return an instance of a sub-class of TextBoundingBox, and that is good.
What is bad is that it can return something entirely else that fails
`is(value, "TextBoundingBox")`.  This flexibility can be useful, but it should be
used very carefully. Functions (and their methods) ideally return the same type
across different calls, and should only differ if they are called with different
arguments that explicitly control the type of the returned value.


## 
Now both margins() and getTextBBox() are methods.





## A Page

Let's turn our attention to unifying the notion of a document
and page across the 2 packages - ReadPDF and Rtesseract.
We might also consider .docx files and Apple's .pages.
But for now, we'll focus on PDF and OCR.

With a PDF document, we convert the entire document to XML
and read that into R via readPDFXML().
We can easily compute the number of pages and access them as
if the document were a list, e.g.,
```
doc = readPDFXML("file")
getNumPages(doc)
getPages(doc)
doc[[3]] # for the third page
doc[c(2, 4, 9)]
```

We can represent a PDF document into an explicit list of pages if we wanted
(with getPages()), but instead we hide the page accessors via methods for 
the `[[` operator.


Some things to consider
+ An OCR document may be a single image or a multi-page document.
+ We also have PDFs that are scanned that we would like to consider
   as OCR documents. So we want to be able to handle this.
+ A single page OCR document is both a document and a page.
+ A single page PDF document is a document that contains a page.


The pdf2png shell script in Rtesseract/inst/bin allows us to call Imagemagick's convert
tool to create write each page as an image.
It generates pages by adding a suffix the file name, e.g.
Shope-1907.pdf maps to
Shope-1970_p0000.png	Shope-1970_p0001.png	Shope-1970_p0002.png.

Given a PDF file, we can convert it to a sequence of images
and then represent the resulting "document" by the names of the files
that were generated.

For now, let's assume that each page is an image for OCR.
We can define a class for this.

setClass("OCRDocument", contains = "character")
setClass("OCRPage", contains = "character")
doc = new("OCRDocument", list.files(pattern = "Shope-1970_.*.png", full = TRUE))

setMethod("[[", "OCRDocument",
           function(x,i, j, ..., exact = TRUE) {
		      new("OCRPage", x[i])
		   })

if(!isGeneric("getTextBBox"))
 setGeneric("getTextBBox",
            function(obj, ...)
             standardGeneric("getTextBBox"))


setMethod("getTextBBox", "OCRPage",
         function(obj, ...) {
  		    # Should be getTextBBox()
		   GetBoxes(as.character(obj), ...)
		 })

Note that we have to use doc[[2]] and not doc[2].
The latter results in an error that there is no method defined for getTextBBox().
In fact, doc[2] should probably return 
+ either an OCRPage, or
+ a OCRDocument with only one page.



setAs("character", "OCRDocument",
       function(from)
	      OCRDocument(from))
		  
OCRDocument =
function(filename, pages = getOCRPageFiles(filename))
{
  if(!file.exists(filename))
    stop("No such file ", filename)
	
  if(length(pages) == 0)
      pages = pdf2png(filename)
}


pdf2png =
function(file, ..., convertCmd = system.file("bin/pdf2png", package = "Rtesseract"),
          .args = list(...))
{
# XXX handle ... - make specific to pdf2png or generic.
   before = list.files(dirname(file), full = TRUE)
   system(sprintf("%s %s %s", convertCmd, paste(.args, collapse = " "), file))
   after = list.files(dirname(file), full = TRUE)
   structure(sort(setdiff(after, before)), class = "Filenames")
}

We may want to have the pdf2png function 
+ create a new temporary directory
+ copy the original file to the new temp directory, 
+ perform the conversion there so that no other process will modify the directory
+ move the generated files back to the original directory
+ remove the temporary directory
+_return the list of newly generated files.

This will guarantee that the files we find at the end will be associated with 
this conversion and not some other application writing into that directory at
the same time.

```
pdf2png =
function(file, ...,
         convertCmd = system.file("bin/pdf2png", package = "Rtesseract"),
         .args = list(...), .dir = tempdir(check = TRUE))
{
    # XXX handle ... - make specific to pdf2png or generic.
	# if .args has names, we should use those - but how
	#  -name value or --name=value

    file = normalizePath(file)
    cur = getwd()
    on.exit({setwd(cur); unlink(list.files(.dir, full.names = TRUE));unlink(.dir)})

    setwd(.dir)
    if(!file.copy(file, file.path(.dir, basename(file))))
        stop("Problem copying original file")
    
    before = list.files(".", full = TRUE)
    system(sprintf("%s %s %s", convertCmd, paste(.args, collapse = " "), basename(file)))
    after = list.files(".", full = TRUE)
    files = sort(setdiff(after, before))
    file.copy(files, cur)
    
    structure(file.path(cur, files), class = "Filenames")
}
```

Note that this assumes convert and pdf2png will write into the same
directory as the input.  We can avoid this for pdf2png.
Not certain what convert assumes.


The function can also check to see if the conversion is actually necessary
or if there are already files with the expected names in the same directory
as the original file.
I wrote the function getConvertedFiles() to do this
Originally I wrote it as
```
getConvertedFilenames =
function(file, dir = dirname(file), base = rmExt(basename(file), ext),
         suffix = "_p[0-9]+\\.png",
         ext = getExt(basename(file)))
{
  list.files(dir, pattern = sprintf("%s%s", base, suffix), full.names = TRUE)
}
```
with the supporting functions
```
getExt =
function(filename)
{
    gsub(".*\\.", "", filename)
}

rmExt =
function(filename, ext)
{
   gsub("\\.$", "", gsub(ext, "", filename, fixed = TRUE))
}
```
Firstly, it is a good thing to write the signature of
getConvertedFilenames() first and to write out the default
values for the methods.
We immediately try to think of these default values in terms of calls to functions
that don't yet exist rather than inlining the code directly there.
This allows us to 
+ think conceptually in terms of tasks, not detail code,
+ reuse the functions elsewhere
+ test the functions independently of this getConvertedFilenames functio
+ simplifies debugging these helper operations because we can test them separately.

Originally, I thought we needed the extension of the original file to put it back
onto the numbered files. Rather than compute it twice, we'll compute it once.
This reduces the computations and also ensures they are consistent.
But, of course these generated files end in png, not pdf. 
So we don't need the value of ext again.
So we should simplify the function's default values
as
```
base = rmExt(basename(file))
```
and omit the `ext` parameter entirely.
```
getConvertedFilenames =
function(file, dir = dirname(file), base = rmExt(basename(file)),
         suffix = "_p[0-9]+\\.png")
{

}
```
We might want to lift the pattern into parameters with the same default value
as defined in the code.
This allows the caller to specify any different pattern that might have been used.
I did this to end up with
```
getConvertedFilenames =
function(file, dir = dirname(file),
         base = rmExt(basename(file)),
         suffix = "_p[0-9]+\\.png",
         pattern = sprintf("%s%s", base, suffix))
{
  list.files(dir, pattern = pattern, full.names = TRUE)
}
```
As always, use codetools::findGlobals or CodeAnalysis::findGlobals
to determine if we are using undefined variables.


At this point, we have code to take a (scanned) PDF file 
and split it into one file per page as an image and
then to represent that original PDF document 
as a conceptual document made up of a sequence of file names.
We can extract an individual page and get its bounding box.


Treating a document as a sequence of filenames is not ideal.
Other actions on the machine can remove one of the pages.
Instead, we would like to read the contents immediately and use those.
We could do this by reading the resulting images (PNG files) into
R. We can create a different class for this if we wanted, say
OCRImages that extends Document.

setClass("OCRImages", contains= c("Document", "list"))
