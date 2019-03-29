---
layout: page
title: BibLaTeX/Biber
---

[BibLaTex](http://www.ctan.org/pkg/biblatex) / 
[Biber](http://www.ctan.org/pkg/biber) (or 
[biblatex-biber.sf](http://biblatex-biber.sourceforge.net/)) is the 
more modern TeX community replacement for the older 
[BibTeX](http://ctan.org/pkg/bibtex) reference management system.

BibLaTeX itself is a set of LaTeX macros which are used to format 
bibliographies.

BibLaTeX uses bibtex-like reference databases (as well as other 
formats).

If using a bibtex-like reference database you can use either the old 
bibtex or the new biber tools to select and sort the references for a 
given LaTeX document. BibLaTeX *only* uses either bibtex or biber to do 
the selection and sorting, these tools *do not do* any formating, that 
is done inside LaTeX using the BibLaTeX macros.

We add some additional fields to simplify our backend Jekyll/Octopress 
based reference system. In particular we fold the entry type into the 
field '[entrytype](#entrytype)', and the cite identifier/key into the 
field '[citekey](#citekey)'.  Since our old system used a mixture of 
journal and author based cite keys, and we have now moved to 
exclusively author based cite keys, we fold the origianl cite key into 
the BibLaTex ids field '[ids](#ids)' to hold the old cite id. Finally, 
to help document the order in which I added references (and so 
discovered them), we include the '[creationid](#creationid)' field 
which is simply the old Aigaion database primary key as an integer.

# BibLaTeX entry types

{% assign entryTypes = site.data['biblatexTypes'] %}

{% include entryTypeList.html %}

# BibLaTeX field types

{% assign fieldTypes = site.data['biblatexFields'] %}

{% include fieldTypeList.html %}


