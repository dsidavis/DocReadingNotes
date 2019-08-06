
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
  + findAbstract - anyTextToLeft, cleanAbstract, columnOf, findAbstractDecl, findEIDAbstract, findKeywordDecl, findSectionHeaders, getBBox, getBBox2, getColPositions, getDocFont, getFontInfo, getNodesBetween, getShiftedAbstract, getSubmissionDateInfo, getTextByCols, hasCoverPage, isBioOne, isEID, isNodeIn, margins, mostCommon, pageOf, readPDFXML, sapply, spansColumns
  + getTextByCols - getBBox2, getColPositions, getXPathDocFontQuery, lapply, orderByLine, sapply
  + findShortLines - nodesByLine, getLineEnds
  + getLineEnds - getBBox2. Takes nodes. Need it to take subset of bbox on the line.
  + nodesByLine - arrangeLineNodes, getBBox2, getDocFont, pageOf
  + isCentered - getBBox2, getTextByCols, inColumn
  + getColPositions - getBBox2, getXPathDocFontQuery
  + inColumn - getBBox2, getLineEnds, getTextByCols, nodesByLine, identicalInColumn (compares XML nodes, but could do on row of bbox),

  + pageOf - does it make sense for scanned documents - yes, but not for page.

  + hasCoverPage - ultimately XPath expressions. 
  + getNumPages - getNodeSet
  + getPages - getNodeSet  
  
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




#
```
ls("package:ReadPDF")
```
```
 [1] "bodyLine"           "columnOf"           "convertPDF2XML"     "dim"                "findAbstract"       "findSectionHeaders" "findTable"          "getBBox"            "getBBox2"          
[10] "getColPositions"    "getDatePublished"   "getDocFont"         "getDocText"         "getDocTitle"        "getDocTitleString"  "getDocWords"        "getFontInfo"        "getLines"          
[19] "getLinks"           "getNumCols"         "getNumPages"        "getPageFooter"      "getPageHeader"      "getPageLines"       "getPages"           "getPublicationDate" "getSectionText"    
[28] "getShapesBBox"      "getTables"          "getTextBBox"        "getTextByCols"      "getTextFonts"       "inColumn"           "isBold"             "isCentered"         "isItalic"          
[37] "isScanned"          "isScanned2"         "lapply"             "length"             "margins"            "pdf_text"           "pdfText"            "plot"               "readPDFXML"        
[46] "sapply"             "showPage"          
```

#
```
setdiff(ls(asNamespace("ReadPDF"), all = TRUE), ls("package:ReadPDF"))
```
```
  [1] ".__C__ConvertedPDFDoc"                  ".__C__ConvertedPDFPage"                 ".__C__PDFToXMLDoc"                      ".__C__PDFToXMLPage"                    
  [5] ".__C__XMLInternalElement"               ".__NAMESPACE__."                        ".__S3MethodsTable__."                   ".__T__coerce:methods"                  
  [9] ".__T__columnOf:ReadPDF"                 ".__T__dim:base"                         ".__T__lapply:base"                      ".__T__length:base"                     
 [13] ".__T__sapply:base"                      ".packageName"                           ".S3MethodsClasses"                      "[.ConvertedPDFDoc"                     
 [17] "[[.ConvertedPDFDoc"                     "addBBoxColors"                          "anyTextToLeft"                          "arrangeLineNodes"                      
 [21] "assembleLine"                           "attrsToDataFrame"                       "authorsAfterTitle"                      "bboxForDoc"                            
 [25] "cleanAbstract"                          "collapseLine"                           "collapsePageCols"                       "combineBBoxLines"                      
 [29] "combineLines"                           "containsDate"                           "containsFigureCaption"                  "context"                               
 [33] "dim.PDFToXMLPage"                       "extractDate"                            "extRegexp"                              "f"                                     
 [37] "findAbstractDecl"                       "findBibCites"                           "findEIDAbstract"                        "findKeywordDecl"                       
 [41] "findNearestVerticalLine"                "findShortLines"                         "findShortSectionHeaders"                "findVol"                               
 [45] "firstIsolated"                          "fixTitleNodes"                          "flattenPages"                           "gapBetweenSegments"                    
 [49] "getAbstractBySpan"                      "getAuthorAffil"                         "getBBox.list"                           "getBBox.PDFToXMLDoc"                   
 [53] "getBBox.PDFToXMLPage"                   "getBBox.XMLInternalNode"                "getBBox.XMLNodeSet"                     "getBBox2.list"                         
 [57] "getBBox2.PDFToXMLDoc"                   "getBBox2.PDFToXMLPage"                  "getBBox2.XMLInternalNode"               "getBBox2.XMLNodeSet"                   
 [61] "getBelowLine"                           "getCaption"                             "getColPositions.character"              "getColPositions.PDFToXMLDoc"           
 [65] "getColPositions.PDFToXMLPage"           "getColPositions.XMLInternalDocument"    "getColPositions.XMLInternalElementNode" "getColPositions.XMLInternalNode"       
 [69] "getCrossPageLines"                      "getEIDAuthors"                          "getEIDHeadMaterialByFont"               "getFirstTextNode"                      
 [73] "getFontText"                            "getFooterPos"                           "getGap"                                 "getHeader"                             
 [77] "getHLines"                              "getHorizRects"                          "getImages"                              "getItalics"                            
 [81] "getLastNode"                            "getLastRealTextNode"                    "getLineEnds"                            "getMetaData"                           
 [85] "getMonthNames"                          "getNodeColors"                          "getNodeFontInfo"                        "getNodePos"                            
 [89] "getNodesBetween"                        "getNodesWithFont"                       "getNumCols.character"                   "getNumCols.PDFToXMLDoc"                
 [93] "getNumCols.PDFToXMLPage"                "getNumCols.XMLInternalNode"             "getOIETitle"                            "getPageGroups"                         
 [97] "getPageHeight"                          "getPageText"                            "getPageWidth"                           "getPublicationDate1"                   
[101] "getRotatedDownloadNodes"                "getRotatedTable"                        "getRotatedText"                         "getRotation"                           
[105] "getShapesBBox.list"                     "getShapesBBox.PDFToXMLDoc"              "getShapesBBox.PDFToXMLPage"             "getShapesBBox.XMLInternalNode"         
[109] "getShapesBBox.XMLNodeSet"               "getShiftedAbstract"                     "getSubmissionDateInfo"                  "getTableNodes"                         
[113] "getTextAfter"                           "getTextAround"                          "getTextBBox.list"                       "getTextBBox.PDFToXMLDoc"               
[117] "getTextBBox.PDFToXMLPage"               "getTextBBox.XMLInternalNode"            "getTextBBox.XMLNodeSet"                 "getTextFont"                           
[121] "getTextNodeColors"                      "getVerticalRects"                       "getVolume"                              "getXPathDocFontQuery"                  
[125] "getYearFromFileName"                    "getYearFromString"                      "groupLines"                             "hardCols"                              
[129] "hasCoverPage"                           "hasGap"                                 "hasYear"                                "identicalInColumn"                     
[133] "imgSpansPage"                           "interNodeDist"                          "isBibSup"                               "isBioOne"                              
[137] "isBold.character"                       "isBold.data.frame"                      "isBold.XMLInternalNode"                 "isCenteredMargins"                     
[141] "isEID"                                  "isElsevierDoc"                          "isEmergingInfectDisease"                "isItalic.character"                    
[145] "isItalic.data.frame"                    "isLowerCase"                            "isMBio"                                 "isMetaTitleFilename"                   
[149] "isNodeIn"                               "isOIEDoc"                               "isOnLineBySelf"                         "isResearchGate"                        
[153] "isScannedPage"                          "isSectionNum"                           "isTitleBad"                             "isTitleBad.character"                  
[157] "isTitleBad.list"                        "isTitleBad.XMLInternalNode"             "isTitleBad.XMLNodeSet"                  "isUpperCase"                           
[161] "joinLines"                              "lapply.ConvertedPDFDoc"                 "lapply.PDFToXMLDoc"                     "lineSpacing"                           
[165] "margins.character"                      "margins.list"                           "margins.PDFToXMLDoc"                    "margins.PDFToXMLPage"                  
[169] "margins.XMLInternalNode"                "margins.XMLNodeSet"                     "mergeLines"                             "mkColor"                               
[173] "mkDateRegexp"                           "mkLine"                                 "mkLines"                                "mostCommon"                            
[177] "nodesByLine"                            "nodesToTable"                           "notWord"                                "orderByLine"                           
[181] "orderNodes"                             "orderNodesInPage"                       "pageNodesByLine"                        "pageOf"                                
[185] "pageOf.list"                            "pageOf.XMLInternalElementNode"          "pageOf.XMLInternalNode"                 "pageTitle"                             
[189] "pdfText.PDFToXMLDoc"                    "pdfText.PDFToXMLDoc.character"          "pdfText.PDFToXMLPage"                   "pdftohtmlDoc"                          
[193] "plot.PDFToXMLDoc"                       "plot.PDFToXMLPage"                      "QQuote"                                 "reassembleLines"                       
[197] "removeExtension"                        "removeNumPrefixes"                      "removeRotated"                          "renderPage"                            
[201] "sameFileName"                           "sapply.ConvertedPDFDoc"                 "sapply.PDFToXMLDoc"                     "showNode"                              
[205] "showNodes"                              "showTb"                                 "spansColumn"                            "spansColumns"                          
[209] "spansColumns2"                          "spansWidth"                             "splitElsevierTitle"                     "TableNodeRegex"                        
[213] "textAboveTitle"                         "textByFont"                             "textByFonts"                            "trim"                                  
[217] "xfoo"                                   "xmlFile"                                "xmlParsePDFTOHTML"                      "xpathQ"                                
