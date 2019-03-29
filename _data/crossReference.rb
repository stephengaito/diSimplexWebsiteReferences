#!/usr/bin/env ruby

# This ruby script loads a bib*tex.yml file and unpacks the variables 
# into arrays.

require 'yaml'
require 'pp'

def readYAML(inFileName)
  hashObj = Hash.new
  File.open(inFileName) do | inFile |
    hashObj = YAML.load(inFile.read)
  end
  hashObj
end

def unpackFieldsFromTypes(typesObj)
  typesObj.keys.sort.each do | entryType |
    entry = typesObj[entryType]

    requiredFields = entry.delete('requiredFields')
    requiredFields = requiredFields.strip.split(/,[ \t\n]+/) if 
      requiredFields.is_a?(String)
    entry['requiredFields'] = requiredFields.sort

    entry['usefulFields'] = "" unless
      entry.has_key?('usefulFields')
    usefulFields = entry.delete('usefulFields')
    usefulFields = usefulFields.strip.split(/,[ \t\n]+/) if 
      usefulFields.is_a?(String)
    entry['usefulFields'] = usefulFields.sort

    optionalFields = entry.delete('optionalFields')
    optionalFields = optionalFields.strip.split(/,[ \t\n]+/) if 
      optionalFields.is_a?(String)
    entry['optionalFields'] = optionalFields.reject { | item |
      usefulFields.include?(item) 
    }.sort

  end
end

def crossrefField(fieldsObj, aField, fieldType, entryType, fieldsTypesName)
  if fieldsObj.has_key?(aField) then
    fieldsObj[aField][fieldType].push(entryType)
  else
    puts "NO [#{aField}] field found in #{fieldsTypesName}"
  end
end

def crossrefFieldsInTypes(typesObj, fieldsObj, fieldsTypesName)
  fieldsObj.each_pair do | fieldType, field |
    field['requiredBy']  = Array.new unless field.has_key?('requiredBy')
    field['usefulFor']   = Array.new unless field.has_key?('usefulFor')
    field['optionalFor'] = Array.new unless field.has_key?('optionalFor')
    typeStr = field.delete('type')
    if typeStr =~ /\(/ then
      typeArray = typeStr.split(/\(/)
      field['structure'] = typeArray[0].strip
      field['type']      = typeArray[1].sub(/\)[ \t]*$/,'').strip
    else
      field['structure'] = 'field'
      field['type']      = typeStr
    end
  end
  typesObj.keys.sort.each do | entryType |
    entry = typesObj[entryType]
    entry['requiredFields'] = Array.new unless entry.has_key?('requiredFields')
    entry['requiredFields'].each do | aField |
      crossrefField(fieldsObj, aField, 'requiredBy',
                    entryType, fieldsTypesName)
    end
    entry['usefulFields'] = Array.new unless entry.has_key?('usefulFields')
    entry['usefulFields'].each do | aField |
      crossrefField(fieldsObj, aField, 'usefulFor',
                    entryType, fieldsTypesName)
    end
    entry['optionalFields'] = Array.new unless entry.has_key?('optionalFields')
    entry['optionalFields'].each do | aField |
      crossrefField(fieldsObj, aField, 'optionalFor',
                    entryType, fieldsTypesName)
    end
  end
end

def addCrossRefs(hashObj)
  hashObj.each_pair do | key, value |
    value['bibtex']   = Array.new unless value.has_key?('bibtex')
    value['biblatex'] = Array.new unless value.has_key?('biblatex')
    value['amsrefs']  = Array.new unless value.has_key?('amsrefs')
    value['aigaion']  = Array.new unless value.has_key?('aigaion')
  end
end

def crossrefFormats(biblatex, bibtex, amsrefs, aigaion)
  addCrossRefs(biblatex)
  addCrossRefs(bibtex)
  addCrossRefs(amsrefs)
  addCrossRefs(aigaion)

  bibtex.keys.sort.each do | bibtexKey |
    bibtexValue = bibtex[bibtexKey]
    bibtexValue['bibtex'].push(bibtexKey)
    bibtexValue['biblatex'].each do | aBiblatexKey |
      if biblatex.has_key?(aBiblatexKey) then
        biblatex[aBiblatexKey]['bibtex'].push(bibtexKey)
      else
        puts "NO [#{aBiblatexKey}] in bibtex(#{bibtexKey}) xref"
      end
    end
  end

  amsrefs.keys.sort.each do | amsrefsKey |
    amsrefsValue = amsrefs[amsrefsKey]
    amsrefsValue['amsrefs'].push(amsrefsKey)
    amsrefsValue['biblatex'].each do | aBiblatexKey |
      if biblatex.has_key?(aBiblatexKey) then
        biblatex[aBiblatexKey]['amsrefs'].push(amsrefsKey)
      else
        puts "NO [#{aBiblatexKey}] in amsrefs(#{amsrefsKey}) xref" unless
          [ 'inbook', 'book', 'inconference', 'conference'].include?(aBiblatexKey)
      end
    end
  end

  aigaion.keys.sort.each do | aigaionKey |
    aigaionValue = aigaion[aigaionKey]
    aigaionValue['aigaion'].push(aigaionKey)
    aigaionValue['biblatex'].each do | aBiblatexKey |
      if biblatex.has_key?(aBiblatexKey) then
        biblatex[aBiblatexKey]['aigaion'].push(aigaionKey)
      else
        puts "NO [#{aBiblatexKey}] in aigaion(#{aigaionKey}) xref"
      end
    end
  end

  biblatex.keys.sort.each do | biblatexKey |
    biblatexValue = biblatex[biblatexKey]
    biblatexValue['biblatex'].push(biblatexKey)
  end

end

def writeYAML(hashObj, outFileName)
  File.open(outFileName, 'w') do | outFile |
    hashObj.keys.sort.each do | aKey |
      aValue = hashObj[aKey]
      if aKey =~ /\[/ then
        outFile.puts "'#{aKey}':"
      else
        outFile.puts "#{aKey}:"
      end
      comment = aValue.delete('comment')
      if comment =~ /\n/ then
        outFile.puts "  comment: |"
        comment.each_line do | aLine |
          outFile.puts "    #{aLine}"
        end
      else
        outFile.puts "  comment: #{comment}"
      end
      aValue.keys.sort.each do | aSubKey |
        aSubValue = aValue[aSubKey]
        if aSubValue.is_a?(Array) then
          if aSubValue.empty? then
            outFile.puts "  #{aSubKey}: []"
          else
            outFile.puts "  #{aSubKey}:"
            aSubValue.each do | aSubSubValue |
              outFile.puts "  - #{aSubSubValue}"
            end
          end
        else
          outFile.puts "  #{aSubKey}: #{aSubValue}"
        end
      end
      outFile.puts
    end
  end
end

biblatexTypes  = readYAML('biblatexTypes.yml.orig')
biblatexFields = readYAML('biblatexFields.yml.orig')
bibtexTypes    = readYAML('bibtexTypes.yml.orig')
bibtexFields   = readYAML('bibtexFields.yml.orig')
amsrefsTypes   = readYAML('amsrefsTypes.yml.orig')
amsrefsFields  = readYAML('amsrefsFields.yml.orig')
aigaionTypes   = readYAML('aigaionTypes.yml.orig')
aigaionFields  = readYAML('aigaionFields.yml.orig')

unpackFieldsFromTypes(biblatexTypes)
unpackFieldsFromTypes(bibtexTypes)
unpackFieldsFromTypes(amsrefsTypes)
unpackFieldsFromTypes(aigaionTypes)

crossrefFieldsInTypes(biblatexTypes, biblatexFields, 'biblatex')
crossrefFieldsInTypes(bibtexTypes,   bibtexFields,   'bibtex')
crossrefFieldsInTypes(amsrefsTypes,  amsrefsFields,  'amsrefs')
crossrefFieldsInTypes(aigaionTypes,  aigaionFields,  'aigaion')

crossrefFormats(biblatexTypes,  bibtexTypes,  amsrefsTypes,  aigaionTypes)
crossrefFormats(biblatexFields, bibtexFields, amsrefsFields, aigaionFields)

writeYAML(biblatexTypes,  'biblatexTypes.yml')
writeYAML(biblatexFields, 'biblatexFields.yml')
writeYAML(bibtexTypes,    'bibtexTypes.yml')
writeYAML(bibtexFields,   'bibtexFields.yml')
writeYAML(amsrefsTypes,   'amsrefsTypes.yml')
writeYAML(amsrefsFields,  'amsrefsFields.yml')
writeYAML(aigaionTypes,   'aigaionTypes.yml')
writeYAML(aigaionFields,  'aigaionFields.yml')

#
# Copy a couple of other yaml files from *.yml.orig to *.yml
# This allows us to rm *.yml at will ;-)
#
system("cp monthNum2Names.yml.orig monthNum2Names.yml")
system("cp citationFieldOrder.yml.orig citationFieldOrder.yml")
system("cp biblatexFieldOrder.yml.orig biblatexFieldOrder.yml")
system("cp biblatexFieldsXapianTerms.yml.orig biblatexFieldsXapianTerms.yml")
