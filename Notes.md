## plot.DocumentPage in Dociface
+  Should we use
```
getTextBBox(x, color = TRUE)
 # or
    #  as(x, "TextBoundingBox")
```
  Or should getTextBBox() have color, rotation, pages, etc. all be TRUE.
  
  
+ Where do we define getTextBBox() - 
  + Dociface.  
  + or leave it only in ReadPDF - NO!
  

+ Can't have exported S3 methods for getTextBBox.list  as otherwise they get called when we have an
  OCRDocument
   because that is more 

+ [Done] if we switch dim(PDFToXMLPage) method to reverse the order so that it is rows/height and then
  width, what will break?
  + A quick grep of that code shows very few direct access by index - only one use, referring to
    dim(page)[2]
	+ This is height so we use that name.
	+ This is in getLines()/getHLines() in depreciated.R
  + Remove the method definition in pages.R
  + put names on the result from the method in ops.R


+ Should we have this in Dociface
-setAs("Document", "TextBoundingBox",
-      function(from) {
-          pgs = getPages(from)
-          tmp = lapply(pgs, as, "TextBoundingBox")
-          ans = do.call(rbind, tmp)
-          ans$page = rep(seq(along = pgs), sapply(tmp, nrow))
-          ans
-      })


+ How to define ProcessedOCRDocument to contain OCRDocument 
  but pass the validity.
   + Introduce new virtual class for OCRDocument and have both extend that.
   + Or have OCRResults be a/extend DocumentPage
      + Won't work since using setOldClass() and that is quite rigid in allowing new class
        hierarchy definitions based on the ordering and combination of classes.
   +  If we have a list of OCRResults, then the plot should just work (?)
      + Good reason to have as(x, "OCRResults") or as(x, "TextBoundingBox")
+ Note the getTextColors() method in the plot()


+ Discuss plot.Document and plot.MultiPageDocument and how we modified the former a little
 (to add pages parameter) to reuse the same code.
  + needed to remove the MultiPageBoundingBox class from each page after splitting the Multipage
    into a BoundingBox for each separate page.
  + Calling plot.Document directly is not ideal as it doesn't allow for extensibility by others.
    + Could put a class on the list of BoundingBox'es for the pages like we do in
      ProcessedOCRDocument.
	  Inclination was to do this for a ProcessedDocument class in Dociface.
	  Then have ProcessedOCRDocument inherit from this. But that is tricky to arrange
	  because of ProcessedOCRDocument inherits from OCRDocument to get dispatch and so would need
	  to inherit from 2 classes.  This is achievable, but not straightforward due to S3 and S4
	  and setOldClass being used.
	  
	  
+ in getTextLines(), we don't use a method for DocumentPage and TextBoundingBox. 
  Instead, we just coerce the bbox to a TextBoundingBox. So if the caller passes
  a page, then
  
  
  
+ We had setAs("OCRPage", "TextBoundingBox", function(from) GetBoxes(from))
  In experimenting with various paths through the plot() methods,
  ```
   doc = OCRDocument("ScannedEgs/Ogunkoya-1990.pdf")
   plot(doc[[2]]
   ```
   showed the lines but no text.
   It turned out that the code to scale the cex according to the fonts
   was making the cex almost 0 for the text.
   The reason was that there was a box returned by GetBoxes() which had 
   the same height as the entire page - 3000.
   But we had added code to remove these very large boxes when we discovered this phenomenon 
   when computing the fontSize and fontName for an OCRPage. So why wasn't it working?
   Because we did that in the getTextBBox method for OCRPage, not in GetBoxes.
   And the coercion from OCRPage to TextBoundingBox skipped getTextBBox and went straight 
   to GetBoxes, omitting the post-processing.
   One could argue we should have put the filtering in GetBoxes and we almost did, but decided
   not to (for backward compatability and to return the raw, unfiltered results).
   But the moral is 1) not to short-circuit the primary function getTextBBox in the setAs() method,
   2) keep a single path through the code.



+ If we just define a method for left() for ShapeBoundingBox, it isn't found.
In Dociface:
```
setMethod("left", "ShapeBoundingBox", function(x, ...) x$x0) 
```
Then
```
doc3 = readPDFXML("../ReadPDF/inst/samples/ElectricA2A_DPL_08-19-13.xml")
sh = getShapesBBox(doc3) 
[1] "MultiPageBoundingBox" "PDFShapesBoundingBox"
[3] "PDFBoundingBox"       "ShapeBoundingBox"    
[5] "data.frame"          
 ```
 This is because the class of the object we are operating is this 5 element vector.
 We need to establish the relationship between the classes in this class-vector
 In ReadDPF, we define
```
setOldClass(c("PDFShapesBoundingBox", "PDFBoundingBox", "ShapeBoundingBox", "data.frame"))
setOldClass(c("MultiPageBoundingBox", "PDFShapesBoundingBox")) 
```
Then R finds the methods for left, etc. when called on `sh`.

