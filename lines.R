if(FALSE) {
    o = findLineBreaks(bb1)
    ll = split(bb1, cut(bb1$top + bb1$height, o))
    ll.txt = sapply(ll, function(x) paste(x$text[order(x$left)], collapse = " "))

    o = findLineBreaks(bb1, asPosition = FALSE)
    sapply(o, function(x) paste(x$text[order(x$left)], collapse = " "))

    o = findLineBreaks(bb2, asPosition = FALSE)
    sapply(o, function(x) paste(x$text[order(x$left)], collapse = " "))    
    
    if(FALSE) {
        # using the old return  value during experimentation
    plot(o$dens, type = "b")
    abline(v = sapply(o$starts, min), col = "green")

    ss = sapply(o$starts, min)
    ll = split(bb1, cut(bb1$top + bb1$height, ss))
    ll.txt = sapply(ll, function(x) paste(x$text[order(x$left)], collapse = " "))        
}
    

    if(FALSE ) {
    # No longer appropriate. Was working from the un-subsetted grps.
    # But idea/concept is fine.        
      abline(v = sapply(o$starts, min), col = c("red", "green")[o$r$values + 1])
      pcols = unlist(mapply(function(x, val) rep(if(val) "green" else "red", length(x)), o$starts, o$r$values))
      points(o$dens$x, o$dens$y, col = pcols)
    }
}

findLineBreaks =
    #
    # This works reasonably well.
    # However, it fails on a few lines on the first page of Amada-2013.pdf, specifically
    # it returns
    #  "(J.   Arikawa). Corresponding E-mail   addresses: author.   j   arika@med.hokudai.ac.jp Tel.: +81 11 706 6905; ,   yosimatu@med.hokudai.ac.jp fax: +81 11 706 6906. oped spp.   for   detection   of   SEOV   IgG   antibody   in   blood   from   Rattus
    # which combines pieces from 3 lines at the bottom of the first column and one line in the second column.
    # This is because the text in the first column at this point is in a smaller font.
    # If we split by column first, then we would solve this.
    # But since we also detect the columns by resolving the lines first, we have a circularity
    # However, we can return to split by lines within the columns so it would be
    #  lines
    #  columns
    #  lines within columns
function(bbox, bw = 3, minInRun = 3, minDelta = 0, asPositions = TRUE)
{
    # compute the density of the bottom location, but weight the values
    # based on the length of the "word", either as the width or nchar(bbox$text)
    h = rep(bbox$top + bbox$height, bbox$width)    
    dens = density(h, bw = bw)

    # Look at the change in the density. We are looking for the increasing parts of the curve
    # where there are several points in a row that have increasing y so the difference is positive
    #!!!!XXXX    bad variable d       delta = c(0, diff(d$y))   This caused me a long debug session.
    delta = c(0, diff(dens$y))
    # 
    runs = rle(delta >= minDelta)
    # Get an group identifier for each observation in dens$x as to which run it is in.
    g = rep(1:length(runs$length), runs$length)

    # group the dens$x into the groups and then only keep this for which
    # the change is > minDelta and also that the run has at least minInRun
    grps = split(dens$x, g)
    w = runs$values & runs$length >= minInRun
    starts = sapply(grps[w], min)

    if(asPositions)
        starts
    else 
        split(bbox, cut(bbox$top + bbox$height, starts))

    
     # And again bad variable x = d$x    in "casual" version.
     # list(x = dens$x, delta = delta, delta2 = delta2, dens = dens, r = runs, starts = starts, g = g)
}


