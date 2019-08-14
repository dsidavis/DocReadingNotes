## General
+ Look at Jane's Change Point mechanism

+ [in progress] Define classes in Dociface and connect to 
   + S3 or S4.
   + DocumentPage, Document in ReadPDF   


## General Implementation

+ Documentation of functions in Dociface
+ Vignette describing the Dociface setup, classes, approach
+ Sample documents for tests into Dociface or wherever - 
+ Implement more functions from ReadPDF and Rtesseract in Dociface
+ Remove all the code in ReadPDF and Rtesseract that is no longer being used.
+ TEST existing functions.

## More Recent and Specific.

1. [HIGH] Rationalize the signature for the generic and methods for getTextBBox, getShapesBBox, getTextByCols and getColPositions
    + font, nodes
    + what is the diffs params for in getTextBBox

1. plot() incorporate what we do for OCR/PDF. 
    + merge code from ReadPDF and Rtesseract.
    + [done] add the shapes from getShapesBBox()
	+ show images (PDF)
	+ any other additions (name of document, page number, ...)

1. plot shapes for OCR documents
    + getShapesBBox() returning NULL, but is calling Rtesseract::getLines.
	   + but findLines() is returning an empty Pix.
	+ needed vert = 3 for that example.

1. Fix plot() of rectangles in shapes. Amada-2003.xml page 1.

1. Get correct image locations in pdftohtml.

1. Put images into the shapes bounding box

1. Possibly make OCRResults a DocumentPage ??
     + no longer needed.  
     + Can't recall offhand why we might have wanted to do this.

1. getColPositions() methods.
    + Claim we can do this almost entirely within Dociface from the BoundingBox.
    + Allow customization via fonts, headers, footers, etc.
	+ findEmptyRegion() - enhance
	   + lines that cross the position and split the page into 2 or more groups.
       + Handle images.
	
1. Need a mechanism in many functions to be able to filter the XML nodes in a page before processing
  them.
    + e.g. in margins - get rid of rotated text on right or the http on the bottom.
        + have the rotation field so can filter on that.
            + but not in the call from PDFToXMLPage.
       	    + possibly  use a `subset = quote(rotation == 0)` argument and NSE !!!!
        + So default is to use all but need a method for XMLNodeSet.
        + Use BBox but identify rows in BBox for the rows to include/omit.
		+ Perhaps filter after computing Bounding Box in a one-shot deal to discard
 		  extraneous content.
  		    + But different from doing it per-call.

1. left, etc. method for ShapeBoundingBox. Not finding method.

1. [enhance] Get a better way to represent the OCRDocument so that we avoid reprocessing it.
    + New class ProcessedOCRDocument which is  a Document, perhaps an OCRDocument, but 
      is a list of TextBoundingBox objects and we dispatch differently.
    + ProcessedDocument class in Dociface
    + Add the Shapes boxes
   
1. *Check/Fix*  dim() method for OCRResults (Dociface/R/plot.R)
    + method for bounding box needs to give those of data.frame
    + so need getPageHeight() and getPageWidth() for BBox for OCR and PDF.
  
1. Added imageDims() method for b(????)

1. getLines is now a function in 2 packages - ReadPDF and Rtesseract
   + Hardly used at all in Rtesseract within the package, but in related code.
     + Change name.

1. getFooter, getHeader from the bbox only.

1. margins - 
    + add top and bottom.
	  + easy to get the top and bottom extremes, but need to deal with headers and footers
    + ignore headers and footers.
    + drop rotated text in PDF/XML.
    + for OCR page and different columns in TextBoundingBox (??? is this the top and bottom versus width and height)
  
1. Figure out if ShapesBoundingBox should have different names for the elements 
    + not x0,x1, y0, y1
    + also stroke and fill.
    + And what do we get from Rtesseract
 
1. [CHECK] clean up getShapesBBox 
    + (meaning what?)  

1. Fonts - determine approach for dealing with these.
    + We now put these into the TextBoundingBox when available.
      + fontSize(), fontName() generics and methods.
      + [done] fix the plot() method for TextBoundingBox to not access x$fontSize but to call a method.
	
1. isBold/isItalic - added to bounding box - YES
    + generic and methods for isBold(). Returns vector of NAs by default.
    	+ for PDFTextBoundingBox, columns fontIsBold, fontIsItalic now present.  Don't use
          directly - isBold, isItalic.
    + if only optionally in BoundingBox, have to check if it is in the column names
	  + should we fill in the redundant font name, size, etc. information.
    + if not present, can't determine it from the row of the BBox.
	
1. [Check being used] Put name of file, page number and dimension on the OCRResults object and the
   BoundingBox generally.
    + [done] DO FOR XML - pageDimensions and getPageHeight and getPageWidth methods.
    + [done] Added in getTextBBox.OCRPage as file and pageDimensins.
    + [done] Take the pageDimensions off as we already have imageDims.
  

If we use the BBox throughout, then perhaps we can justify the expense of
computing all columns (e.g. font, color, etc.) we may need down-stream.


## Done

1. [Done - tests/plot.R] Resolve `Warning: replacing previous import ‘Dociface::plot’ by ‘graphics::plot’ when loading
  ‘Rtesseract’`
    + Changed the order and the message doesn't appear.  But check works as we want.

1. [Done] In plot() method, allow caller to control whether the axes are shown or not and if 
  so, don't change the margins.
    + Can be useful to see the axes when doing calculations.
	+ Works for OCR and PDF.

1. [Done] lapply() and sapply() methods for Document.

1. [Done] In OCR, getTextBBox() should drop rows with height = getPageHeight


