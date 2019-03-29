---
layout: page
title: BibTex
---

[BibTeX](http://ctan.org/pkg/bibtex) is the old (La)TeX reference 
management system.  It is now largely phased out in favour of 
[BibLaTeX](http://www.ctan.org/pkg/biblatex).

# BibTeX entry types

{% assign entryTypes = site.data['bibtexTypes'] %}

{% include entryTypeList.html %}

# BibTeX field types

{% assign fieldTypes = site.data['bibtexFields'] %}

{% include fieldTypeList.html %}
