## General
+ Look at Jane's Change Point mechanism

+ Define classes in Dociface and connect to 
   + S3 or S4.
   + DocumentPage, Document in ReadPDF   

## More Recent and Specific.

+ Get a better way to represent the OCRDocument so that we avoid reprocessing it.
  + New class ProcessedOCRDocument which is  a Document, perhaps an OCRDocument, but 
    is a list of TextBoundingBox objects and we dispatch differently.

+ Put name of file, page and dimension on the OCRResults object and the BoundingBox generally.

+ margins - 
  + top and bottom.
  + for OCR page and different columns in TextBoundingBox
  + drop rotated text in PDF/XML.
  
+ Figure out if ShapesBoundingBox should have different names for the elements 
  + not x0,x1, y0, y1
  + also stroke and fill.
  + And what do we get from Rtesseract
  
+ Rationalize the signature for the generic and methods for getTextBBox, getShapesBBox.

+ Figure out signature for getTextByCols and getColPositions
  + font, nodes
  
+ [CHECK] clean up getShapesBBox 
  + (meaning what?)  
  
+ Need a mechanism in many functions to be able to filter the XML nodes in a page before processing
  them.
  + So default is to use all but need a method for XMLNodeSet.
  + Use BBox but identify rows in BBox for the rows to include/omit.

+ isBold - added to bounding box
  + if optionally in BoundingBox, have to check if it is in the column names
  + if not present, can't determine it from the row of the BBox.

+ Fonts - determine approach for dealing with these.

+ [CHECK - tests/plot.R] Resolve `Warning: replacing previous import ‘Dociface::plot’ by ‘graphics::plot’ when loading
  ‘Rtesseract’`
  + Changed the order and the message doesn't appear.  But check works as we want.
  
+ Finish the plot(doc) and plot(page) to incorporate what we do for OCR.  
  + i.e. the other additions.
  
+ [Done] In plot() method, allow caller to control whether the axes are shown or not and if 
  so, don't change the margins.
    + Can be useful to see the axes when doing calculations.
	+ Works for OCR and PDF.



If we use the BBox throughout, then perhaps we can justify the expense of
computing all columns (e.g. font, color, etc.) we may need down-stream.
