# getTitle() for OCR and PDF Documents

Consider the problem of getting the text of the title 
of a document. We'll focus on journal articles for now and we'll generalize later.


We start with the notion that we have a Document object.
This might represent the contents of a PDF or a scanned
document. (We can generalize to Word, Pages, Google Documents, etc.)



The function getDocTitleString() we developed in ReadPDF for the Zoonotics articles
is a reasonable place to start, but we will come back to that and start more simply.
Let's assume that the title is generally the text that is tallest on the first page.
It also typically occurs near the top of the content/page. (This is not true when
new articles start anywhere on the page after a previous article.)

Let's read a relatively simple PDF document
```
library(ReadPDF)
doc = readPDFXML("../SamplePDFs/Klempa-2003.xml")
```
We look at the fonts defined on the first page
and find the largest in size:
```
fi = getFontInfo(doc[[1]])
fi[fi$size == max(fi$size), ]
```
```
  id size family   color isItalic isBold isOblique                     name
3  3   22  Times #231f20    FALSE  FALSE     FALSE  GFOPPF+Dutch801BT-Roman
4  4   22  Times #231f20     TRUE  FALSE     FALSE GFPAAA+Dutch801BT-Italic
```
Both are 22 point fonts and one is italic and the other is not.
We get this from isItalic, but also from the name. Neither source
is entirely reliable, but worth checking

Let's get the text on this page that is rendered via these fonts
```
library(XML)
tiNodes = getNodeSet(doc[[1]], ".//text[@font = 3 or @font = 4]")
```
The text values are
```
sapply(tiNodes, xmlValue)
```
```
[1] "Genetic Interaction between Distinct Dobrava Hantavirus Subtypes in" "Apodemus agrarius"                                                  
[3] "and"                                                                 "A"                                                                  
[5] "."                                                                   "flavicollis"                                                        
[7] "in Nature"                                                          
```
We have identified the title.


We have used the representation of the PDF document as XML in several ways:
+ getFontInfo
+ getNodeSet and xmlValue

We also only used the first page via `doc[[1]]`.

We will assume that the user has to create the initial document, although
we can take care of this based on the extension in the filename and a preset
list of possible functions or classes.  (We would use the classes to create
as("character", "TargetClass") methods that just call the corresponding function, 
e.g., readPDFXML()).



## An OCR Document
Firstly, an OCR document will not tell us about its fonts.
However, we can guess the size of the fonts based on the size 
of the text elements it recovers.


Let's consider a simple scanned document - Shope-1982.pdf
We have converted this to a series of PNG files.
We get the bounding for the first page, corresponding to `doc[[1]]` above.
This is a data.frame but currently has different names than that for PDF.
We compute the height of each text segment:
```
sh = GetBoxes("../ScannedEgs/Shope-1982_p0000.png")
sh$height = sh$top - sh$bottom
```
Now we can do the equivalent of what we did above - find the
text with the largest size:
```
m = max(sh$height)
sh[ sh$height == m, ]
```
We get our title exactly - "Rabies-Related Viruses"


### A Second OCR Document and Complications

Let's look at a similar scanned document, but with a wrinkle.
Looking at the first page, we see that the text that is tallest is NOTES
and this is not our title.
We move ahead, however, following are approach from above:
```
sh = GetBoxes("../ScannedEgs/Shope-1970_p0000.png")
sh$height = sh$top - sh$bottom
```
If we look at height we find some very large numbers that are definitely errors coming form the OCR.
So we subset the bounding box data.frame to sensible numbers.
```
sh = sh[sh$height < 1000, ]
```
Now we can find the text corresponding to the largest height
```
m = max(sh$height)
sh[ sh$height == m, ]
```
This does not work. This is just the letter g.  It has a low confidence value.
We have to relax the exact equality for the maximum.
(We also want to see where on the page this simpe "g" is located.)

If we look for something within, say, 20% of the maximum height,
we pick up 
```
w = (m - sh$height ) < .2*m
```
```
   left bottom right top            text confidence height
26 1112    456  1493 528   Serologically   90.77170     72
28 1953    463  1988 549               g   56.54856     86
29  425    548   910 620 Morphologically   91.19328     72
```
We can now get all the text on those two lines.
Except for the garbage which we will detect along the right margin (the URL for the download of this
scanned document), we will hopefully get our text.
Using somewhat imprecise values for the range of top and bottom, we get
```
subset(sh, bottom < 560 & top > 456)
```
```
   left bottom right top            text confidence height
23  452    459   578 510             Two   88.04880     51
24  606    457   834 509         African   90.52705     52
25  863    458  1082 510         Viruses   90.79159     52
26 1112    456  1493 528   Serologically   90.77170     72
27 1521    456  1628 508             and   91.89778     52
28 1953    463  1988 549               g   56.54856     86
29  425    548   910 620 Morphologically   91.19328     72
30  938    547  1164 600         Related   90.85082     53
32 1275    547  1473 599          Rabies   90.52162     52
33 1501    547  1661 598           Virus   92.10978     51
34 1953    553  1988 610               3   95.19558     57
```
This includes all of the text we wanted except the "to" before "Rabies Virus".
If we allow bottom to be up to 570 (rather than 560), we do include the text "to" in our results.
We also include g and 3. Note that these are both quite far on the right
and probably from the text in the right margin.


It is slightly strange we didn't have to contend with the word "NOTES" being the largest.
If we examine all the text we get below the word Printed and about Morphologically that is in the
title with
```
subset(sh, top > 220 & bottom < 500)
```
we don't see anything resembling NOTES or where it is located. In this case, the OCR seems to have
omitted it!


### Another OCR Document

Let's return to our original PDF document and treat it as if it were scanned.
We'll convert the original PDF pages to a sequence of images.
```
library(Rtesseract)
bb = GetBoxes("../SamplePDFs/Klempa-2003_p0000.png")
```

Let's compute the heights of each term
```
bb$height = bb$top - bb$bottom
```

We find the maximum height.
This just returns 3338 which is probably the entire page.
So we have to look at a more sane subset of the entries
```
bb = bb[ bb$height < 1000,]
```
Again, we might look for exact equality for the maximum word height, but
we'll use within 20% of the maximum height
```
m = max(bb$height)
w = abs(m - bb$height) < m*.2
```
```
    left bottom right  top                 text confidence height
32  1941    426  2192  490             Subtypes   91.19566     64
34   583    501   882  564             Apodemus   86.99874     63
38  1352    500  1617  564          flavicollis   87.14504     64
789  218   2921   619 2990 g;{g?gﬁ;?g:ﬁ;?{i%ﬁs0   40.18659     69
```
The text for the largest value of height (69 in row 4) is gibberish.
(Note that the background color for the image is quite dark! See if pdf2png and convert can correct
this.) <!-- FIX -->
The other 3 entries *are* in the title.
So, as we did above, we can find the text on the "same" lines with
```
subset(bb, bottom < 520 & top > 410)
```
```
   left bottom right top        text confidence height
26  242    427   464 475     Genetic   90.82345     48
27  489    428   802 475 Interaction   91.34804     47
28  826    426  1062 475     between   91.27517     49
29 1087    428  1309 475    Distinct   90.45700     47
30 1334    426  1579 475     Dobrava   90.32870     49
31 1603    428  1916 475  Hantavirus   91.21810     47
32 1941    426  2192 490    Subtypes   91.19566     64
33 2218    442  2269 474          in   96.60712     32
34  583    501   882 564    Apodemus   86.99874     63
35  905    517  1123 564    agrarius   91.87949     47
36 1151    501  1252 550         and   90.30635     49
37 1268    502  1335 550          A.   90.01064     48
38 1352    500  1617 564 flavicollis   87.14504     64
39 1643    517  1695 549          in   93.12268     32
40 1719    503  1917 550      Nature   90.45403     47
```
And we have recovered our title, as we did in the original PDF.



### Another PDF Document with a Twist

Consider ../SamplePDFs/Amada-2013.pdf.

```
doc = readPDFXML("../SamplePDFs/Amada-2013.xml")
fi = getFontInfo(doc[[1]])
fi[fi$size == max(fi$size), ]
```
```
  id size family   color isItalic isBold isOblique                name
6  6   18  Times #000000    FALSE  FALSE     FALSE BIFOCK+OneGulliverA
9  9   18  Times #231f20    FALSE  FALSE     FALSE   BIFOCI+GulliverRM
```
We cannot tell if these are italic, bold or neither. The RM at the end of BIFOCI+GulliverRM
suggests regular "roman". However, the BIFOCI suggets italics. These are wild guesses.

We get the text with
```
tiNodes = getNodeSet(doc[[1]], ".//text[@font = 6 or @font = 9]")
sapply(tiNodes, xmlValue)
```
```
 [1] "Journal"         "of"              "Virological"     "Methods"         "Rapid,"          "whole"           "blood"           "diagnostic"      "test"            "for"            
[11] "detecting"       "anti-hantavirus" "antibody"        "in"              "rats"           
```
This is almost correct, but includes the name of the journal - "Journal of Virological Methods".
We can separate these out based on the locations of the lines of text, or via a heuristic that
the title doesn't start with "Journal of ...."

However, what if the title of the journal was in a font slightly bigger than the title, ../SamplePDFs/Allison-2015.pdf.
In that case, we would get the wrong title using our approach - "NIH Public Access"
```
doc = readPDFXML("../SamplePDFs/Allison-2015.xml")
fi = getFontInfo(doc[[1]])
id = fi[fi$size == max(fi$size), "id"]
tiNodes = getNodeSet(doc[[1]], sprintf(".//text[@font = %s]", id))
sapply(tiNodes, xmlValue)
```

Again, we would implement a heuristic to go to the second largest font and so on.
```
id = fi[  fi$size == max(fi$size[fi$size < max(fi$size)]), "id"]
tiNodes = getNodeSet(doc[[1]], sprintf(".//text[%s]", paste(sprintf("@font = %s", id), collapse= " or ")))
sapply(tiNodes, xmlValue)
```
Unfortuntely, this picks up two fonts of the same size and one of these is a rotated font
corresponding to annotations/decorations on the PDF in the margin. Again, we can detect this.



## Abstracting the Approach across PDF and OCR.

We now have some software engineering decisions about how to best implement an abstract
version of getDocTitleString() that can work for both PDF and OCR documents.
We want to 
+ share as much code a possible so that the approach is the same, e.g., identifying journal titles
  rather than the article title;
+ take advantage of the additional information we have from the PDF document;
+ allow for different levels of precision due to the OCR and PDF fonts

Again, we are only working on the simplified version of this problem at this stage.
We will add more later based on our original implementation of getDocTitleString().
For now, we focus on the PDF and OCR integration.


The PDF version could be implemented as
```
getTitle.pdf =
function(filename, doc = readPDFXML(filename),
          fi = getFontInfo(doc[[1]]))
{
   id = fi[fi$size == max(fi$size), "id"]
   sapply(id, function(id) 
                 paste(xpathSApply(doc[[1]], sprintf(".//text[@font = %s]", id), xmlValue), collapse = " "))
}
```
This finds the text corresponding to the largest sized font, but keeps the text for each font
separate in the result.
The result from our first document is 
```
ti = getTitle.pdf("../SamplePDFs/Klempa-2003.xml")
```
```
                                                                                    3                                                                                     4 
"Genetic Interaction between Distinct Dobrava Hantavirus Subtypes in and . in Nature"                                                     "Apodemus agrarius A flavicollis"
```
These two should be interleaved. We can do this based on the positions of the nodes.

Alternatively, we could implement this to keep the text from the nodes in the same order as they
appear in the PDF (which is not necessarily as they appear on the page) with
```
getTitle.pdf =
function(filename, doc = readPDFXML(filename),
          fi = getFontInfo(doc[[1]]))
{
   id = fi[fi$size == max(fi$size), "id"]
   paste(xpathSApply(doc[[1]], sprintf(".//text[%s]", paste(sprintf("@font = %s", id), collapse= " or ")), xmlValue), collapse = " ")
}
```

```
ti = getTitle.pdf("../SamplePDFs/Klempa-2003.xml")
```
```
[1] "Genetic Interaction between Distinct Dobrava Hantavirus Subtypes in Apodemus agrarius and A . flavicollis in Nature"
```


The OCR function might be
```
getTitle.OCR = 
function(filename, doc = as(filename, "OCRDocument"),
         bbox = GetBoxes(doc[[1]]), pct = .2, frac = 4)
{
   b2 = max(bbox$bottom)/4
   bbox$height = bbox$top - bbox$bottom
   bbox = bbox[ bbox$height < 1000,]
   m = max(bbox$height)
   w = abs(m - bbox$height) < m*pct & bbox$bottom  < b2
   tmp = bbox[w, c("top", "bottom")]
   subset(bbox, bottom < max(tmp$bottom) + m/frac & top > min(tmp$top) - m/frac)
}
```

```
bb = GetBoxes("../SamplePDFs/Klempa-2003_p0000.png")
getTitle.OCR(bbox = bb)
```

```
bbox2 = GetBoxes("../ScannedEgs/Shope-1982_p0000.png")
getTitle.OCR(bbox = bbox2, pct = .02)
```


Let's compare the two functions getTitle.pdf and getTitle.OCR at the sub-task level.
It is hard to identify the tasks precisely - either being too high-level  or too
detailed/implementation-specific


+ each function takes a file name
+ each reads the document
+ each extracts the first "page"
+ the PDF function 
  + finds the font information to find the tall text
  + finds text with the tallest font
+ the OCR function 
  + gets the Bounding Box for the text 
  + finds the tallest text
  + finds the text "near" that tallest text that is at least on the first 1/4 of the page.



We could rewrite parts of the getTitle.OCR 
function to condense the expressions into higher-level functions.
The goal is to get to the high-level concepts so that we can 
do the same task for both OCR and PDF.


In this function, we
+ compute the bbox height since the GetBoxes() function doesn't do this. 
  + **We might add this as an  option or provide it as an equivalent to getFontInfo().**
+ compute the height of the page, and the extent/height of the first quarter
  + We didn't do this for our PDF examples, but we did include it in our conceptual criteria. So we
    can extend both functions to (optionally) include this.
+ exclude nonsense text because of the large height 
  + **this is OCR specific due to errors in the recognition**
  + Either 
    + have a no-op function/method for PDF but a real one for OCR
	+ or check if `is(doc, "OCR")`
+ find the text within the top quarter of the page for text "near" the few tallest words.
  + If the PDF fonts are the same size, we don't need to do this.
     + If the PDF fonts are not identically the same size, we do need to do this.
  + Compute wiggle room above and below based on whether we are dealing with OCR or PDF
    + Again if `is(doc, "OCR")` or a method for computing the wiggle with a no-op for PDF.
  
```
function(filename, doc = as(filename, "OCRDocument"),
         bbox = GetBoxes(doc[[1]]), pct = .2, frac = 4)
{
   bbox$height = bbox$top - bbox$bottom
   bbox = discardNonsense(bbox) 
   getTallestText(bbox, pct, frac)
} 
```

```
getTallestText = 
function(bbox, pct = .2, frac = 4, pageQtr = max(bbox$bottom)/4,
         mx = max(bbox$height))
{
   w = abs(mx - bbox$height) < mx*pct & bbox$bottom  < b2
   tmp = bbox[w, c("top", "bottom")]
   subset(bbox, bottom < max(tmp$bottom) + mx/frac & top > min(tmp$top) - m/frac)
}
```
```
discardNonsense = 
function(bbox, height = bbox$top - bbox$bottom, cutoff = 1000)
{
  bbox[ height < cutoff, ]
}
```
