---
layout: page
title: Aigaion
---

[Aigaion](http://sourceforge.net/projects/aigaion/) is my old web-based 
reference management system.  It has now been phased out in preferece 
for a BibLaTeX flavoured reference management system based on 
jekyll/octopress and static files.

# Aigaion entry types

{% assign entryTypes = site.data['aigaionTypes'] %}

{% include entryTypeList.html %}

# Aigaion field types

{% assign fieldTypes = site.data['aigaionFields'] %}

{% include fieldTypeList.html %}
