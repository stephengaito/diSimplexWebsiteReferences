---
layout: page
title: AMSrefs
---

The [amsrefs](http://www.ams.org/publications/authors/tex/amsrefs) 
system is the [AMS](http://www.ams.org) equivilant to biber.

The AMS will accept bibliographies in either the amsrefs or Bibtex 
formats.

# AMSrefs entry types

{% assign entryTypes = site.data['amsrefsTypes'] %}

{% include entryTypeList.html %}

# AMSrefs field types

{% assign fieldTypes = site.data['amsrefsFields'] %}

{% include fieldTypeList.html %}

