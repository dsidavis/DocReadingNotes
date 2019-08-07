+ Look at Jane's Change Point mechanism
+ Define classes in Dociface and connect to 
   + S3 or S4.
   + DocumentPage, Document in ReadPDF   
+ margins - 
  + top and bottom.
  + for OCR page and different columns in TextBoundingBox
  + drop rotated text in PDF/XML.
  
+ isBold - added to bounding box
  + if optionally in BoundingBox, have to check if it is in the column names
  + if not present, can't determine it from the row of the BBox.



If we use the BBox throughout, then perhaps we can justify the expense of
computing all columns we may need down-stream.
