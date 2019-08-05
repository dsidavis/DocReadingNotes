
# nodesByLine() Function


```
function (nodes, asNodes = TRUE, bbox = getBBox2(nodes, TRUE), 
    baseFont = getDocFont(as(nodes[[1]], "XMLInternalDocument")), 
    fontSize = if (nrow(baseFont) > 0) baseFont$size else 11, 
    addText = TRUE, useBase = TRUE, rotate = FALSE) 
{
    if (length(nodes) == 1 && xmlName(nodes[[1]]) == "page") 
        nodes = getNodeSet(nodes, ".//text")
		
    if (length(nodes) == 0) 
        return(list())
		
    pgnum = sapply(nodes, pageOf)
	
    if (length(unique(pgnum)) > 1) {
        tmp = tapply(nodes, pgnum, nodesByLine, asNodes, baseFont = baseFont, 
            fontSize = fontSize, addText = addText, rotate = rotate)
        return(structure(unlist(tmp, recursive = FALSE, use.names = FALSE), 
            names = unlist(lapply(tmp, names))))
    }
    if (rotate) 
        bbox = structure(bbox, names = c("top", "left", "height", 
            "width", "text"))
    if (useBase) 
        bbox$top = bbox$top + bbox$height
    intv = seq(0, max(bbox$top) + fontSize - 1, by = fontSize)
    topBins = cut(bbox$top, intv)
    byLine = lapply(split(nodes, topBins), arrangeLineNodes, 
        asNodes)
    names(byLine) = sapply(byLine, arrangeLineNodes, FALSE)
    byLine[sapply(byLine, length) > 0]
}
```

+ We can pass a BBox.
+ If we wanted to get back to XML nodes, we can 
	+ put the nodes in a named list with id's being 1:n
	+ create a column of id values in the BBox 1:n
	+ return the relevant bbox id
	+ get the nodes from the list.
	
+ need the page number of the text element.
  + If doing this across pages of an OCR document, add these to the BBox.

+ need estimate of fontSize


+ arrangeLineNodes
  + gets left attribute and arranges, so we can just pass the bbox or even the left element.




