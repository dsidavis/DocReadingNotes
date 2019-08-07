OCR2PDFTextBBox =
function(from) {
  # bottom and right map to width and height in PDF BBox.
  ans = data.frame(left = from$left, top = from$top, width = from$right - from$left, height = from$top - from$bottom, text = from$text, stringsAsFactors = FALSE)
  class(ans) = c("PDFTextBoundingBox", "PDFBoundingBox", "data.frame")
  ans
} 

setOldClass(c("WordOCRResults", "OCRResults", "data.frame"    ))
setOldClass(c("PDFTextBoundingBox", "PDFBoundingBox", "data.frame"))
setAs("OCRResults", "PDFTextBoundingBox", OCR2PDFTextBBox)




contentByLine =
    #
    # Need to relax the accuracy to match lines for 
    #
    #
function(bbox, asNodes = TRUE,
         baseFont = NULL, fontSize = 11,
#        baseFont = getDocFont(as(nodes[[1]], "XMLInternalDocument")), 
#         fontSize = if (nrow(baseFont) > 0) baseFont$size else 11, 
         addText = TRUE, useBase = TRUE, rotate = FALSE, var = "bottom", maxDiff = 13,
         tolerance = getTolerance(bbox))   # was "top"
{
    orig = bbox # in case we need the class.
    
    bbox = as(bbox, "PDFTextBoundingBox")
    if(var == "bottom")
      bbox$bottom = bbox$top - bbox$height
    
    if (nrow(bbox) == 0) 
        return(list())

    if("page" %in% names(bbox)) {
      pgnum = bbox$page

#XXX FIX - change nodes to bbox      
      if (length(unique(pgnum)) > 1) {
           tmp = tapply(nodes, pgnum, nodesByLine, asNodes, baseFont = baseFont, 
                           fontSize = fontSize, addText = addText, rotate = rotate)
           return(structure(unlist(tmp, recursive = FALSE, use.names = FALSE), 
                            names = unlist(lapply(tmp, names))))
       }
    }
    
    if (rotate)  
        bbox = structure(bbox, names = c("top", "left", "height", "width", "text"))

    if (useBase) 
        bbox$top = bbox$top + bbox$height

    #X Could have a method for the original bbox to get the line base points using density.
    intv = getLineGaps(bbox[[var]])
browser()    
#    intv = seq(0, max(bbox[[var]]) + fontSize - 1, by = fontSize)
#    browser()
#    br = findBreaks(bbox$top)
    
    topBins = cut(bbox[[var]], intv)
    byLine = lapply(split(bbox, topBins), arrangeLineNodes, asNodes)
    names(byLine) = sapply(byLine, arrangeLineNodes, FALSE)
    byLine[sapply(byLine, nrow) > 0]
}


arrangeLineNodes =
function(bbox, asNodes = TRUE)
{
    bbox = bbox[order(bbox$left),]
    if(asNodes) 
        bbox
    else
        paste(bbox$text, collapse = " ")
}


findBreaks =
    #
    # not right yet, if the correct approach at all.
    #
    # Idea is to find the 0 values in the density and these are the gaps where there is nothing
    # and the points between the lines/elements.
    #
function(vals, bw = 3, epsilon = 3*min(o$y))#.Machine$double.eps)    
{
    de = density(vals, bw)
    sq = seq(min(vals), max(vals))
    o = approx(de$x, de$y, xout = sq)
    w = o$y < epsilon
    r = rle(w)
    g = rep(1:length(r$lengths), r$lengths)
    gr = split(sq, g)
browser()    
    ans = c(sq[1]- 1, as.numeric(sapply(gr[r$values], range)), sq[length(sq)] + 1)
}


if(FALSE) {
    v = c(10, 11, 10, 12,
        20, 21, 20, 22,
        30,31,31,32,31,30,31,
        42,40,41,43,44)
    a = findBreaks(v)
}




foo = getLineGaps = 
function(vals, maxDiff = 13)
{
    v2 = sort(unique(vals))     
    while(TRUE) {
browser()        
       delta = diff(c(0, v2))
       w = delta < maxDiff
       i = which(w)
       if(length(i) == 0)
           return(v2)
       v2 = v2[ - (i-1)]
   }
   v2
}


if(FALSE) {
    # "../ScannedEgs/Mebatsion-1992_p0000.png"
    b1 = zzz[[1]]
    truth = unname(sapply(split(b1$text, cut(b1$bottom, foo(b1$bottom, 13))), paste, collapse = " "))
}





setMethod("getTolerance", "WordOCRTextBoundingBox",
          function(box) {
      # elaborate computation 
          })
          
setMethod("getTolerance", "OCRTextBoundingBox",
          function(box) {
              switch(class(bbox)[1],
                     "Line" = 2,
                     "Para" = 10,
                     "Symbol" = .5
          }
          )
