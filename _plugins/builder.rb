require 'jekyll/utils'
require 'refsLiquidTags'

module Builder

  def page2liquid(page)
    deep_merge_hashes(
      page[:metaData],
      {
        "content"       => page[:content],
        "path"          => page[:file],
        "url"           => page[:url],
        "biblatexUrl"   => page[:url].sub(/\.html/, '.bib'),
        "bibcontextUrl" => page[:url].sub(/\.html/, '.lua'),
        "citationsUrl"  => page[:url].sub(/\.html/, 'Citations.html')
      }
    )
  end

  def renderContentLiquid(content, payload, info)
    Liquid::Template.parse(content).render!(payload, info)
  end

  def renderContentMarkdown(content)
    Kramdown::Document.new(content).to_html
  end

  def renderPageLiquid(output, page, site, payload, info)
    output = output.dup
    layout = site.layouts[payload['page']['layout']]

    used   = Set.new([layout])
    while layout
      payload = deep_merge_hashes(
        payload, 
        {
          "content" => output,
          "page"    => page2liquid(page),
          "layout"  => layout.data
        }
      )
      output = renderContentLiquid(
        layout.content,
        payload,
        info
      )
      layout = site.layouts[layout.data["layout"]]
      if layout then
        if used.include?(layout)
          layout = nil
        else
          used << layout
        end
      end
    end
    output
  end

  def renderPage(page, site)
    payload = deep_merge_hashes({
      "page" => deep_merge_hashes( 
        page[:metaData],
        page2liquid(page)
      )
    }, site.site_payload)

    info = {
      filters:   [Jekyll::Filters],
      registers: { :site => site, :page => payload['page'] }
    }

    output = page[:content]
    output = renderContentLiquid(output, payload, info)
    output = renderContentMarkdown(output)
    output = renderPageLiquid(output, page, site, payload, info)
    return if output.nil? or output.empty?

    outFileName = site.config['destination']+'/'+page[:url]
    FileUtils.mkdir_p(File.dirname(outFileName))
    File.open(outFileName, 'w') do | outfile |
      outfile.write(output)
    end
  end

  def createBibLaTeXPage(page)
    biblatexPage = page.clone
    biblatexPage[:metaData]['layout'] = 'biblatex'
    biblatexPage[:url] = page[:url].sub(/\.html$/,'.bib')
    biblatexPage
  end

  def createBibConTeXtPage(page)
    bibcontextPage = page.clone
    bibcontextPage[:metaData]['layout'] = 'bibcontext'
    bibcontextPage[:url] = page[:url].sub(/\.html$/,'.lua')
    bibcontextPage
  end

  def addIndexItem(index, indexKey, key, url, linkText, auxText = "")
    index[indexKey] = Hash.new unless index.has_key?(indexKey)
    index[indexKey][key] = {
      'url'      => url,
      'linkText' => linkText,
      'auxText'  => auxText
    }
  end

  def addIndexPages(basePath, baseTitle, page)
    fileName       = File.basename(page[:file], '.md')
    oneLetter      = fileName[0]
    twoLetters     = fileName[0..1]
    indexFile      = 'index.md'
    zeroLetterPath = "#{basePath}/#{indexFile}"
    oneLetterPath  = "#{basePath}/#{oneLetter}#{indexFile}"
    twoLetterPath  = "#{basePath}/#{twoLetters}/#{twoLetters}#{indexFile}"

    zeroLetterIndex = loadJekyllDataFile(zeroLetterPath)
    oneLetterIndex  = loadJekyllDataFile(oneLetterPath)
    twoLetterIndex  = loadJekyllDataFile(twoLetterPath)

    zeroLetterIndex[:metaData]['title'] = "#{baseTitle} index"
    zeroLetterIndex[:metaData]['layout'] = "index"
    zeroLetterIndex[:changed] = true

    oneLetterIndex[:metaData]['title']  = "#{baseTitle} '#{oneLetter}' index"
    oneLetterIndex[:metaData]['layout'] = "index"
    oneLetterIndex[:changed] = true

    twoLetterIndex[:metaData]['title']  = "#{baseTitle} '#{twoLetters}' index"
    twoLetterIndex[:metaData]['layout'] = "index"
    twoLetterIndex[:changed] = true

    Dir.glob(basePath+'/*').each do | aFile |
      next if aFile =~ /\.+$/
      next unless File.directory?(aFile)
      dirName = File.basename(aFile)[0]
      indexUrl = basePath+'/'+dirName+'index.html'
      addIndexItem(zeroLetterIndex[:metaData], 'rootIndex',
                   dirName, indexUrl, dirName)
      addIndexItem(oneLetterIndex[:metaData], 'rootIndex',
                   dirName, indexUrl, dirName)
      addIndexItem(twoLetterIndex[:metaData], 'rootIndex',
                   dirName, indexUrl, dirName)
    end unless zeroLetterIndex.has_key?(:rootIndex) && 
      oneLetterIndex.has_key?(:rootIndex) &&
      twoLetterIndex.has_key?(:rootIndex)
    zeroLetterIndex[:rootIndex] = true
    oneLetterIndex[:rootIndex] = true
    twoLetterIndex[:rootIndex] = true

    Dir.glob(basePath+'/'+oneLetter+'*').each do | aFile |
      next if aFile =~ /\.+$/
      next unless File.directory?(aFile)
      dirName = File.basename(aFile)
      indexUrl = basePath+'/'+dirName+'/'+dirName+'index.html'
      addIndexItem(oneLetterIndex[:metaData], 'index',
                   dirName, indexUrl, dirName)
      addIndexItem(twoLetterIndex[:metaData], 'subIndex',
                   dirName, indexUrl, dirName)
    end unless oneLetterIndex.has_key?(:index) &&
      twoLetterIndex.has_key?(:subIndex)
    oneLetterIndex[:index]    = true
    twoLetterIndex[:subIndex] = true

    if basePath == 'cite' then
      addIndexItem(twoLetterIndex[:metaData], 'index',
                   fileName, page[:url], fileName, page[:metaData]['title'])
    else
      addIndexItem(twoLetterIndex[:metaData], 'index',
                   fileName, page[:url], page[:metaData]['title'])
    end
  end

  def addCitationItem(index, year, citeKey, url, title)
    indexKey = "#{year}#{citeKey}"
    linkText = "#{year} #{citeKey}"
    index[indexKey] = {
      'url'      => url,
      'linkText' => linkText.gsub(/\s/,' '),
      'auxText'  => title
    }
  end

  def addAuthorCitationPages(page)
    biblatex = page[:metaData]['biblatex']
    ['author', 'bookauthor', 'commentator',
     'editor', 'editora', 'editorb', 'editorc',
     'holder', 'translator'].each do | aNameField |
      if biblatex.include?(aNameField) then
        biblatex[aNameField].each do | anAuthor |
          citationPath = author2urlBase(anAuthor)+'Citations.md'
          citationUrl  = citationPath.sub(/\.md$/, '.html')
          citations    = loadJekyllDataFile(citationPath)
          citations[:changed]              = true
          citations[:metaData]['layout']   = "authorCitations"
          citations[:metaData]['citeKeys'] = Hash.new unless
            citations[:metaData].has_key?('citeKeys')
          addCitationItem(citations[:metaData]['citeKeys'],
                          biblatex['year'], biblatex['citekey'],
                          page[:url], biblatex['title'])
        end
      end
    end
  end

  def buildCitation(page, site)
    addIndexPages("cite", "Citation", page)
    addAuthorCitationPages(page)
    renderPage(page, site)
    renderPage(createBibLaTeXPage(page), site)
    renderPage(createBibConTeXtPage(page), site)
    removeFromDataFileCache(page[:file])
  end

  def buildAuthor(page, site)
    renderPage(page, site)
    addIndexPages("author", "Author", page)
    removeFromDataFileCache(page[:file])
  end

  def buildAPage(page, site)
    renderPage(page, site)
    removeFromDataFileCache(page[:file])
  end

  def buildList
    [ "referenceSchemas", "cite", "author" ]
  end

  def buildPage(page, site)
    case page[:file]
    when /^cite/
      buildCitation(page, site)
    when /^author/
      buildAuthor(page, site)
    else
      buildAPage(page, site)
    end
  end

  def clearDataFileCache
    @jekyllDataFiles = Hash.new
  end

  def cachingLoadJekyllDataFile(aJekyllDataFile)
    return @jekyllDataFiles[aJekyllDataFile] if
      @jekyllDataFiles.has_key?(aJekyllDataFile)
    #puts "loading: [#{aJekyllDataFile}]"
    someJekyllData = origLoadJekyllDataFile(aJekyllDataFile)
    @jekyllDataFiles[aJekyllDataFile] = someJekyllData

    someJekyllData
  end

  def removeFromDataFileCache(aJekyllDataFile)
    @jekyllDataFiles.delete(aJekyllDataFile)
  end

  def sortKeys(index)
    newIndex = Array.new
    return newIndex if index.nil?
    index.keys.sort.each do | aKey |
      newIndex.push(index[aKey])
    end
    newIndex
  end

  def renderDataFileCache(site)
    puts "Walking through cache (expect #{@jekyllDataFiles.length / 50} dots)"
    count = 0
    @jekyllDataFiles.each_key do | aKey |
      count += 1
      if count.modulo(50) == 0 then
        putc '.'
        $stdout.flush
      end
      page = @jekyllDataFiles[aKey]

      page.delete(:rootIndex)
      page.delete(:index)
      page.delete(:subIndex)
      saveJekyllDataFile(page, '.')

      # This needs to be done AFTER saving
      # since we rebuild the rootIndex/index/subIndex
      # to be arrays for rendering
      #
      if page[:file] =~ /index\.md$/ then
        page[:metaData]['rootIndex'] =
          sortKeys(page[:metaData]['rootIndex'])
        page[:metaData]['index'] =
          sortKeys(page[:metaData]['index'])
        page[:metaData]['subIndex'] =
          sortKeys(page[:metaData]['subIndex'])
      elsif page[:file] =~ /Citations\.md$/ then
        page[:metaData]['citeKeys'] =
          sortKeys(page[:metaData]['citeKeys'])
      end
      renderPage(page, site)

      @jekyllDataFiles.delete(aKey)
    end
    puts ""
  end

end # Builder

module Octopress

#=begin
  class BuildCommand < Command
    extend Jekyll::Utils

    require 'jekyllWalker'
    extend JekyllWalker
    extend Builder

    extend Jekyll::Author2UrlFilter

    class << self
      # monkey patch ourself so that we can implement selective caching
      alias_method :origLoadJekyllDataFile, :loadJekyllDataFile
      alias_method :loadJekyllDataFile,      :cachingLoadJekyllDataFile
    end

    LAST_BUILD = "_site/.lastBuild"

    def self.init_with_program(p)
      p.commands.delete(:build) if p.commands.has_key?(:build)
      p.commands.delete(:b)     if p.commands.has_key?(:b)
      p.command(:build) do |c|
        c.syntax 'build'
        c.description 'my build command'
        c.option 'quite',   '-q', '--quite',   'keep quite about loading/writing'
        c.option 'verbose', '-v', '--verbose', 'report when we load/write files'
        c.action do | args, options |
          options['quite'] = true unless options['verbose']
          options.delete('save')
          @options = options
          clearDataFileCache
          siteOpts = Jekyll.configuration(options)
          site = Jekyll::Site.new(siteOpts)
          site.layouts = Jekyll::LayoutReader.new(site).read
          site.data = Jekyll::DataReader.new(site).read(site.config["data_dir"])
          FileUtils.mkdir_p(site.config['destination'])

          # do this by hand...
          buildPage(loadJekyllDataFile("index.md"), site) unless
            FileUtils.uptodate?(LAST_BUILD, [ "index.md" ])

          recursivelyWalkDir(buildList(), LAST_BUILD) do | someJekyllData |
            # we explicitly ignore index and citation files...
            # they will be processed if needed during the renderDataFileCache
            #
            next if someJekyllData[:file] =~ /.+index\.md$/
            next if someJekyllData[:file] =~ /Citations\.md$/

            buildPage(someJekyllData, site)

            # we DO NOT want the standard walker saving behaviour
            #
            someJekyllData.delete(:changed)
          end
          renderDataFileCache(site)
          FileUtils.touch(LAST_BUILD)
        end
      end
    end
  end
#=end

end # Octopress
