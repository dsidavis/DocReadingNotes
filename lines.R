if(FALSE) {
o = findLineBreaks1(bb1)
plot(o$dens, type = "b")
abline(v = sapply(o$starts, min), col = c("red", "green")[o$r$values + 1])

pcols = unlist(mapply(function(x, val) rep(if(val) "green" else "red", length(x)), o$starts, o$r$values))
points(o$dens$x, o$dens$y, col = pcols)
}

findLineBreaks1 = 
function(bbox, bw = 3, minInRun = 3, minDelta = 0)
{
    # compute the density of the bottom location, but weight the values
    # based on the length of the "word", either as the width or nchar(bbox$text)
    h = rep(bbox$top + bbox$height, bbox$width)    
    dens = density(h, bw = bw)

    # Look at the change in the density. We are looking for the increasing parts of the curve
    # where there are several points in a row that have increasing y so the difference is positive
    #!!!!XXXX    bad variable d       delta = c(0, diff(d$y))
    delta = c(0, diff(dens$y))
    # 
    runs = rle(delta > minDelta)
    # Get an group identifier for each observation in dens$x as to which run it is in.
    g = rep(1:length(runs$length), runs$length)

    # group the dens$x into the groups and then only keep this for which
    # the change is > minDelta and also that the run has at least minInRun
    w = runs$values # & runs$length >= minInRun
    grps = split(dens$x, g)
    starts = grps # [w]
    browser()
    
    delta2 = c(0, diff(delta))
     # And again bad variable x = d$x    in "casual" version.
    list(x = dens$x, delta = delta, delta2 = delta2, dens = dens, r = runs, starts = starts, g = g)
}


findLineBreaks = 
function(bbox, bw = 3, pct = .1)
{
    h = rep(bbox$top + bbox$height, bbox$width)    
    dens = density(h, bw = bw)

    w = dens$y < (min(dens$y)+ pct*(max(dens$y) - min(dens$y)))
    g = cumsum(w)
    browser()
    split(dens$x, g)
}
