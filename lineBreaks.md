
#

How do we find lines in a page?
This seems simple, but is more complicated in actuality.

We'll start with an answer and then show how we evolved to this.


The goal of the function is to break text elements into lines.
The function takes a data.frame with the location of the individual text elements.
These are words and some are on the same line and others are on different lines.
Our task is to group the elements by line.

There n text elements.
We determine the lower (bottom) part of each text element. This is
includes the letters like t, g, q, etc. that have different content below the 
base line. Our job is to  collect words that are very close vertically
and differentiate between words that are far apart.
This is clustering.

The approach we use in this function is the 1-D kernel density.
<!-- show figure of density -->
We use a very small bandwidth to strongly differentiate 
between different vertical values.
```
library(ReadPDF
doc = readPDFXML(list.files("SamplePDFs", pattern = "Amada-2013.xml", full = TRUE))
bb = as(doc[[1]], "TextBoundingBox")
plot(density(bb$top + bb$height, bw = 3), type = "b", xlab = "height from top of page", main = "")
```
While plotted horizontally, recall that we are displaying the distribution of the bottom location of the
text elements. The following shows the distribution corresponding to the page.
```
plot(de$y, 1216 - de$x, type = "b", xlab = "height from top of page", main = "")
```

Looking at the first/horizontal plot, we can see the numeruous "mountains" with a rapid increase 
of the density as we move to the right, a peak, followed immediately by a rapid decrease.
There are also long segments in which the density is effectively 0.
These are the gaps between lines. However, note that not all gaps bewtween lines have a density of
0.   We see this in the run from 700 to 1000.
If we use a bandwidth of 1, we do get the 0 values but only for very small segments.
So using the 0 values  to find the gaps between lines won't work very well.


The idea we us here is to find the rapidly increasing parts of the curve.
We could find both the increase and decrease. However, we found that the decrease is not always
present.
So we find the increase.
To do this, we
+ compute the density
+ find the increasing 
  + take the differences of the density across successive x's
  + find runs of consecutive positive differences (using run length encoding)
+ find the start of each increasing segment 
These starting points define the start of each line segment and so we can 
use these to group the text elements by line.

The current version of this code is
```
findLineBreaks =
    #
    # This works reasonably well. However, it fails on a few lines on the first page of Amada-2013.pdf, specifically
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
      #    h = rep(bbox$top + bbox$height, bbox$width)
    h = rep(bottom(bbox), width(bbox)) 
    dens = density(h, bw = bw)

      # Look at the change in the density. We are looking for the increasing parts of the curve
      # where there are several points in a row that have increasing y so the difference is positive
      #!!!!XXXX    bad variable d       delta = c(0, diff(d$y))   This caused me a long debug session.
    delta = c(0, diff(dens$y))

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
        split(bbox, cut(bottom(bbox), starts))
}
```
+ We note first that this only relies on having the bounding box for the
text positions. This will work for PDF and OCR documents.

+ Secondly, we compute the bottom location of the text elements via the
 method bottom().  This hides the structure of the bounding box and
 there is a method for both PDFTextBoundingBox and OCRResults. So again
 this works for PDF and OCR documents without any change to the code.
 The same applies to the call to width().










Consider the earlier version of this function
```
findLineBreaks1 =
function(bbox, bw = 3, minInRun = 3, minDelta = 0)
{
    h = rep(bbox$top + bbox$height, bbox$width)    
    dens = density(h, bw = bw)

    delta = c(0, diff(dens$y))

    runs = rle(delta >= minDelta)
    # Get an group identifier for each observation in dens$x as to which run it is in.
    g = rep(1:length(runs$length), runs$length)

    # group the dens$x into the groups and then only keep this for which
    # the change is > minDelta and also that the run has at least minInRun
    w = runs$values & runs$length >= minInRun
    grps = split(dens$x, g)
    starts = grps[w]
#    browser()
    
    delta2 = c(0, diff(delta))
     # And again bad variable x = d$x    in "casual" version.
    list(x = dens$x, delta = delta, delta2 = delta2, dens = dens, r = runs, starts = starts, g = g)
}
```



The first commit of this function

```
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

```
