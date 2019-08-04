
# Analyzing the Migrated Functions for Implementation-dependent Functions

Here we analyze the code that Matt brought over from ReadPDF
and possible Rtesseract. We are looking for functions that 
identify the representation of the bounding box, etc.
These will need to be abstracted or encapsulated with methods


```
e = new.env(); lapply(list.files(pattern = "R$"), source, e)
```

```
obj = ls(e)
w = sapply(obj, function(v) is.function(get(v, e)))
```


We should use the findGlobals() in CodeAnalysis, but codetools okay for now.
```
gg = lapply(obj[w], function(v) codetools::findGlobals(get(v, e), FALSE))
```

```
table(unlist(sapply(gg, `[[`, "variables")))
```
Nothing alarming here in terms of using non-local undefined variables.
context is a function we define.


```
setdiff(unlist(sapply(gg, `[[`, "variables")), c(ls(e), ls("package:base")))
```
```
[1] "isCentered"    "pageOf"        "xmlGetAttr"    "xmlValue"     
[5] "getTextBBox"   "getTextByCols" "xmlName"       "median"       
[9] "margins"      
```
+ So we need to define pageOf, isCentered, getTextBBox, getTextByCols, margins in the GetDocElements

+ xmlGetAttr, xmlName, xmlValue are clearly related to the PDF-XML representation.

+ median comes from stats.



Now we look at the functions that are used and 
```
setdiff(unlist(sapply(gg, `[[`, "functions")), c(ls(e), ls("package:base"), ls("package:methods")))
```
```
 [1] "getNodeSet"        "getTextBBox"       "xmlParent"        
 [4] "hasCoverPage"      "isCentered"        "nodesByLine"      
 [7] "pageOf"            "readPDFXML"        "xmlValue"         
[10] "findShortLines"    "median"            "trim"             
[13] "getShapesBBox"     "getBBox2"          "getPages"         
[16] "margins"           "docName"           "getFontInfo"      
[19] "getFontText"       "isBold"            "isScanned"        
[22] "xmlGetAttr"        "getDocFont"        "getBBox"          
[25] "getTextByCols"     "getTextFonts"      "xpathQ"           
[28] "getTextNodeColors" "xmlAttrs"          "findAbstract"     
[31] "getNumPages"       "removeNodes"       "xmlName"          
[34] "getLineEnds"       "URLdecode"         "xpathSApply"      
[37] "getSibling"       
```

+ Conceptually the following should be in GetDocElements as they are implementation independent.  So we need to implement these.
  + findAbstract, hasCoverPage, isCentered, 
  + getTextByCols
  + findShortLines, getLineEnds
  + nodesByLine
  + isCentered
  + hasCoverPage
  + getNumPages, getPages
  + pageOf - does it make sense for scanned documents - yes, but not for page.

+ PDF-XML specific functions probably.
  + getFontInfo, getTextNodeColors, getTextFonts, getDocFont
  + getFontText
  + isBold, isScanned
  + The following are either constructors or internal helper functions that we can hide
    + xpathQ - internal
    + readPDF, readPDFXML - constructor functions

+ From the XML package and so entirely related to the PDF-XML representation.
  + xmlGetAttr, xmlName, xmlParent, xpathSApply, getNodeSet, removeNodes, getSibling, xmlAttrs, docName

+ URLdecode
