#!/usr/bin/env nclsh

infile = addfile(f, "w")

topg = infile->topg

printVarSummary(topg)

print ("xl = "+ xl)
print ("yl = "+ yl)
print ("xh = "+ xh)
print ("yh = "+ yh)
old_block = topg(:,xl:xh,yl:yh)
med = dim_median_n(topg(:,xl:xh,yl:yh), (/1,2/))
print ("median = " + med)
topg(:,xl:xh,yl:yh) = topg(:,xl:xh,yl:yh) < med

infile->thk(:,xl:xh,yl:yh) = infile->thk(:,xl:xh,yl:yh) + (old_block - topg(:,xl:xh,yl:yh))

if .not. isfilevar(infile,"topg_old") then
infile->topg_old=infile->topg
infile->topg_old@standard_name="original topography before digging trenches"
end if 

infile->topg = topg
