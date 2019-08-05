# isCentered() Function

The definition of isCentered() for the PDF-XML content is 
```
function (node, cols = getTextByCols(xmlParent(node), asNodes = TRUE), 
    threshold = 0.2, colNum = inColumn(node, cols)) 
{
    if (length(cols) == 0) 
        return(FALSE)
    bb = getBBox2(cols[[colNum[1]]])
    byLine = by(bb, bb[, "top"], function(x) c(min(x[, "left"]), 
        max(x[, "left"] + x[, "width"])))
    byLine2 = do.call(rbind, byLine)
    pos = apply(byLine2, 2, median)
    mid = median(pos)
    top = xmlGetAttr(node, "top")
    lw = byLine[[top]]
    if (length(lw) && ((lw[1] - pos[1] < 5) || diff(pos) - diff(lw) < 
        40)) 
        return(FALSE)
    textPos = as.numeric(xmlAttrs(node)[c("left", "width")])
    textMid = textPos[1] + textPos[2]/2
    textPos[1] - pos[1] > 0.1 * diff(pos) & abs(textMid - mid) < 
        threshold * median(byLine2[, 2])
}
```
This takes a <text> node. It computes the text nodes for each column
by going up the XML tree to the <page> element containing the node.


+ For OCR content, we could pass the row(s) of the bounding box corresponding to the text element of 
interest.  
  + We would want a method with   (rowIndices, bbox) to avoid  (bbox[rowIndices], bbox)
+ For cols, we could pass the bbox for each column giving the locations (and the text).
We compute this anyway with `getBBox(cols[[colNum[1]]])`.
+ Instead of accesing "top", "width", "left", etc. we can use accessors  or convert the OCR bboxes
  to the same format/names as the PDF bboxes.
+ xmlGetAttr(node, "top") won't be necessary if we pass in the bbox for the row(s) of the nodes of
  interest.


Essentially what we are doing in this function is the following heuristic:
+ arrange the text elements into columns and lines within columns
+ compare the given node to the locations of the end points of the lines


# 

```
z = lapply(body(ReadPDF:::isCentered)[-1], getInputs)
names(z) = sapply(z, function(x) paste(deparse(x@code), collapse = " "))
names(z) = sapply(z, function(x) paste(deparse(x@code), collapse = " "))
```
```
$`if (length(cols) == 0) return(FALSE)`
[1] "cols"

$`bb = getBBox2(cols[[colNum[1]]])`
[1] "cols"   "colNum"

$`byLine = by(bb, bb[, "top"], function(x) c(min(x[, "left"]),      max(x[, "left"] + x[, "width"])))`
[1] "bb"

$`byLine2 = do.call(rbind, byLine)`
[1] "rbind"  "byLine"

$`pos = apply(byLine2, 2, median)`
[1] "byLine2"

$`mid = median(pos)`
[1] "pos"

$`top = xmlGetAttr(node, "top")`
[1] "node"

$`lw = byLine[[top]]`
[1] "byLine" "top"   

$`if (length(lw) && ((lw[1] - pos[1] < 5) || diff(pos) - diff(lw) <      40)) return(FALSE)`
[1] "lw"  "pos"

$`textPos = as.numeric(xmlAttrs(node)[c("left", "width")])`
[1] "node"

$`textMid = textPos[1] + textPos[2]/2`
[1] "textPos"

$`textPos[1] - pos[1] > 0.1 * diff(pos) & abs(textMid - mid) <      threshold * median(byLine2[, 2])`
[1] "textPos"   "pos"       "textMid"   "mid"       "threshold" "byLine2"  
```
