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


+ Note the getTextColors() method in the plot()
