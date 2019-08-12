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
