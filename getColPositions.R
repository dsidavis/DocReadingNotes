getColPositions = 
function(bbox, align = "left", threshold = .99, quantile = .99, bw = 10, minDelta = 10)
{
    vals = switch(align,
                  left = bbox[, "left"],
                  right = bbox[, "left"] + bbox[, "right"],
                  center = (bbox[, "left"] + bbox[, "right"])/2
        )
    
    dens = density(vals, bw = bw)				 
    #    ans = dens$x[  (dens$y - threshold * max(dens$y)) > 0 ]
    ans = dens$x[  (dens$y > quantile(dens$y, quantile)) ]
    ans = floor(ans[diff(c(0, ans)) > minDelta])

    epsilon = quantile(dens$y, .025)
    minDistTo0 = 10
    i = sapply(ans, function(v) {
                    sq = seq(v, max(v-50, min(vals)))
                    p = approx(dens$x, dens$y, xout = sq)$y
                    w = p < epsilon
                    if(!any(w))
                       return(TRUE)
                    v2 = sq[max(which(w))]
                    (v - v2) <= minDistTo0
                })
    ans[i]
}


plot.PDFBoundingBox =
function(x, y, ...)
{
    x$top = max(x$top )- x$top
    plot(x$left, x$top, type = "n", ...)
    text(x$left, x$top, x$text, cex = .5, adj = 0)
}


getColPositions2 = 
function(bbox, align = "left", threshold = .99, bw = 10)
{
    vals = switch(align,
                  left = bbox[, "left"],
                  right = bbox[, "left"] + bbox[, "right"],
                  center = (bbox[, "left"] + bbox[, "right"])/2
                 )
     dens = density(vals, bw = bw)				 
     ans = dens$x[  dens$y > 0 ]

}
