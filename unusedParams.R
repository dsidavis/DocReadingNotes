unusedParams =
function(fun)
{
    f2 = fun
    formals(f2) = NULL
    vars = findGlobals(f2, FALSE)$variables
    setdiff( names(formals(fun)), vars )
}
