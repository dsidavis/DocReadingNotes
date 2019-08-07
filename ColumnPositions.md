# Finding Column Positions


+ Perhaps we should be looking for the gaps in the text to show the end of one column and the start
  of a new column
  + See Amada-2013


We start by examing the code for getColPositions() for a page in a PDF document.
This is currently implemented as 
```
getColPositions.PDFToXMLPage = getColPositions.XMLInternalNode =  getColPositions.XMLInternalElementNode =
    # For a single page
function(page, threshold = .1,
         txtNodes = getNodeSet(page, getXPathDocFontQuery(page, docFont, local = local)),
         bbox = getBBox2(txtNodes), docFont = TRUE, align = "left", local = FALSE, ...)    
{
    bbox = as.data.frame(bbox)
    page = as(page, "PDFToXMLPage")

    vals = switch(align,
                  left = bbox$left,
                  right = bbox$left + bbox$right,
                  center = (bbox$left + bbox$right)/2
                 )
    tt = table(vals)

    if(missing(txtNodes) && nrow(bbox) == 0 && !local) {
             # Use the page-specific font count
        return(getColPositions(page, threshold, docFont = docFont, align = align, local = TRUE, ...))
    }

    # Subtract 2 so that we start slightly to the left of the second column to include those starting points
    # or change cut to be include.lowest = TRUE
    ans = as.numeric(names(tt [ tt > nrow(bbox)*threshold])) - 2

    minDiff = 5
    if(length(ans) > 2 && any(delta <- (diff(ans) <= 20))) {
        # See Forrester-2008
        tt = split(sapply(txtNodes, xmlValue), cut(bbox[,1], c(ans, Inf)))
        w = sapply(tt, function(x) any(grepl("References", x)))
        if(any(w)) {
              # Need to check it is the References column
           minDiff = 20
        }

    }
    
    w = which(diff(ans) < minDiff)
    if(length(w))
        ans = ans[ - (w + 1)]


    if(length(ans) == 1 && ans[1] > .4*dim(page)["width"]) {
           # So only one column and it starts close to the middle of the page. Probably means
           # there is one to the left that we didn't find. This may be because the text is in a different font.
           # So we add the left margin to the one we found.
          ans = c(margins(page)[1], ans)
     }
    
    ans
}
```

Let's break this into conceptual tasks
+ get the bounding box of the text elements
+ find the most common starting positions of words/text
+ determine a cutoff for the number of elements that defines a column.





# Code Analysis

Let's look at the code in terms of the inputs to each expression.
We use CodeDepends to do this.
```
library(CodeDepends)
z = lapply(body(ReadPDF:::getColPositions.PDFToXMLPage)[-1], getInputs)
names(z) = sapply(z, function(x) paste(deparse(x@code), collapse = " "))
```
Now we look at the inputs required for each expression
```
sapply(z, slot, "inputs")
```
```
$`bbox = as.data.frame(bbox)`
[1] "bbox"

$`page = as(page, "PDFToXMLPage")`
[1] "page"

$`vals = switch(align, left = bbox$left, right = bbox$left + bbox$right,      center = (bbox$left + bbox$right)/2)`
[1] "align" "bbox" 

$`tt = table(vals)`
[1] "vals"

$`if (missing(txtNodes) && nrow(bbox) == 0 && !local) {     return(getColPositions(page, threshold, docFont = docFont,          align = align, local = TRUE, ...)) }`
[1] "txtNodes"  "bbox"      "local"     "page"      "threshold" "docFont"   "align"     "..."      

$`ans = as.numeric(names(tt[tt > nrow(bbox) * threshold])) - 2`
[1] "tt"        "bbox"      "threshold"

$`minDiff = 5`
character(0)

$`if (length(ans) > 2 && any(delta <- (diff(ans) <= 20))) {     tt = split(sapply(txtNodes, xmlValue), cut(bbox[, 1], c(ans,          Inf)))     w = sapply(tt, function(x) any(grepl("References", x)))     if (any(w)) {         minDiff = 20     } }`
[1] "ans"      "txtNodes" "bbox"    

$`w = which(diff(ans) < minDiff)`
[1] "ans"     "minDiff"

$`if (length(w)) ans = ans[-(w + 1)]`
[1] "w"   "ans"

$`if (length(ans) == 1 && ans[1] > 0.4 * dim(p)["width"]) {     ans = c(margins(page)[1], ans) }`
[1] "ans" "page"

$ans
[1] "ans"
```

Some general notes
+ page is not used after the coercion to an PDFToXMLPage except in the special case of another call
  to getColPositions. The coercion can be done there.
+ One might think page should already be a PDFToXMLPage given the name of the method, but this
  function is also used for XMLInternalNode, etc. without the explicit PDFToXMLPage class. Therefore,
  the coercion may be necessary to ensure appropriate dispatch later.
+ The coercion of bbox to a data.frame could be be done via getBBox2(, asDataFrame = TRUE) or calling
  getTextBBox(). However, if the caller passes bbox, we need to ensure it is a data.frame.
  

Specifically thinking about how to share much of this code between PDF and OCR documents, we note
the following
+ getBBox2() in the default value for bbox can be replaced with a call to getTextBBox()
  and we have a method for the  OCR page for this also.
+  The call `sapply(txtNodes, xmlValue)` can conceptually be replaced by `bbox$text`.
We have to ensure that bbox is computed from the corresponding set of nodes as there is a possible
path for this not to be the case, i.e., if the caller explicitly passes bbox or a subset of nodes via
txtNodes.  But the typical and default behavior means it will.
+ The getXPathDocFontQuery() is restricting the text nodes of interest to those in the "most common"
  font.  (See ReadPDF:::getDocFont()).
+ Looking at the inputs to each expression, most of the expressions do not rely on
  representation-specific information. Most work on the bbox and other derived variables created earlier in
  the script.
  + page
+ We have dim(page) and so we need a method for that for the OCR.
+ In PDF documents, the alignment position is very accurate. For OCR documents it is less precise
  and there is noise around that value.
  So we may need a different approach for OCR, rather than shared code.
  + We need to find the small interval that has a lot of values.  The kernel density with a small
    bandwith gives us this.



getColPositions.PDFToXMLPage = getColPositions.XMLInternalNode =  getColPositions.XMLInternalElementNode =
    # For a single page
function(page, threshold = .1,
         txtNodes = getNodeSet(page, getXPathDocFontQuery(page, docFont, local = local)),
         bbox = getBBox2(txtNodes), docFont = TRUE, align = "left", local = FALSE, ...)    
{
    bbox = as.data.frame(bbox)
    page = as(page, "PDFToXMLPage")

    vals = switch(align,
                  left = bbox$left,
                  right = bbox$left + bbox$right,
                  center = (bbox$left + bbox$right)/2
                 )
    tt = table(vals)

    if(missing(txtNodes) && nrow(bbox) == 0 && !local) {
             # Use the page-specific font count
        return(getColPositions(page, threshold, docFont = docFont, align = align, local = TRUE, ...))
    }

    # Subtract 2 so that we start slightly to the left of the second column to include those starting points
    # or change cut to be include.lowest = TRUE
    ans = as.numeric(names(tt [ tt > nrow(bbox)*threshold])) - 2

    minDiff = 5
    if(length(ans) > 2 && any(delta <- (diff(ans) <= 20))) {
        # See Forrester-2008
        tt = split(sapply(txtNodes, xmlValue), cut(bbox[,1], c(ans, Inf)))
        w = sapply(tt, function(x) any(grepl("References", x)))
        if(any(w)) {
              # Need to check it is the References column
           minDiff = 20
        }

    }
    
    w = which(diff(ans) < minDiff)
    if(length(w))
        ans = ans[ - (w + 1)]


    if(length(ans) == 1 && ans[1] > .4*dim(page)["width"]) {
           # So only one column and it starts close to the middle of the page. Probably means
           # there is one to the left that we didn't find. This may be because the text is in a different font.
           # So we add the left margin to the one we found.
          ans = c(margins(page)[1], ans)
     }
    
    ans
}






pngs = list.files("ScannedEgs", pattern = "png$", full = TRUE)
zzz = structure(lapply(pngs, GetBoxes), names = basename(pngs))
names(zzz) = pngs


xml = list.files("SamplePDFs", pattern = "xml$", full = TRUE)
xmls = lapply(xml, function(x) { doc = readPDFXML(x); lapply(doc, getBBox2, asDataFrame = TRUE)})
names(xmls) = xmls


pdfs = xml
dev.set(3)
par(mfrow = c( 3, 5)); invisible(mapply(function(d, id) { d = density(d$left, 3); plot(d, main = id, type = "b"); abline(h = quantile(d$y, .99), col = "red")}, pdfs, basename(names(pdfs))))
par(mfrow = c( 3, 5)); invisible(mapply(function(d, id) { dens = density(d$left, 3); plot(dens, main = id, type = "b"); abline(h = quantile(dens$y, .99), col = "red"); abline(v = getColPositions(d, bw = 3), col = "green")}, pdfs, basename(names(pdfs))))

par(mfrow = c( 3, 5)); invisible(mapply(function(d, id) { plot(d, main = id); abline(v = getColPositions(d, bw = 3), col = "green")}, pdfs, basename(names(pdfs))))

dev.set(2)
par(mfrow = c( 4, 5)); invisible(mapply(function(bb, id) { d = density(bb$left, 3); plot(d, main = id, type = "b"); abline(h = quantile(d$y, .99), col = "red")}, zzz, basename(names(zzz))))
par(mfrow = c( 4, 5)); invisible(mapply(function(bb, id) { d = density(bb$left, 3); plot(d, main = id, type = "b"); abline(h = quantile(d$y, .99), col = "red"); abline(v = getColPositions(bb, bw = 3), col = "green")}, zzz, basename(names(zzz))))


