= flickr

== CHANGE LOG:
 2010-09-04
 --------------------------------------
 - Made the framework more modular, earlier it had one file for everything, API, models etc.
 - Fixed a bug when parsing photo_collections - they weren't parsed properly
 - Updated tests (all pass)
 - Tested with Rails 3.0
 - Added Gemfile
 
 This is a work in progress, it might not function properly!

== DESCRIPTION:

An insanely easy interface to the Flickr photo-sharing service. By Scott Raymond. (& updated May 08 by Chris Taggart, http://pushrod.wordpress.com, updated Sept 04 by Sebastian Johnsson, http://www.sebastianjohnsson.com)

== FEATURES/PROBLEMS:

The flickr gem (famously featured in a RubyonRails screencast) had broken with Flickr's new authentication scheme and updated API.
This has now been largely corrected, though not all current API calls are supported yet.

== SYNOPSIS:

require 'flickr'
flickr = Flickr::Api.new('some_flickr_api_key')    # create a flickr client (get an API key from http://www.flickr.com/services/api/)
user = flickr.users('sco@scottraymond.net')   # lookup a user
user.name                                     # get the user's name
user.location                                 # and location
user.photos                                   # grab their collection of Photo objects...
user.groups                                   # ...the groups they're in...
user.contacts                                 # ...their contacts...
user.favorites                                # ...favorite photos...
user.photosets                                # ...their photo sets...
user.tags                                     # ...their tags...
user.popular_tags							  							# ...and their popular tags
recentphotos = flickr.photos                  # get the 100 most recent public photos
photo = recentphotos.first                    # or very most recent one
photo.url                                     # see its URL,
photo.title                                   # title,
photo.description                             # and description,
photo.owner                                   # and its owner.
File.open(photo.filename, 'w') do |file|
  file.puts p.file                            # save the photo to a local file
end
flickr.photos.each do |p|                     # get the last 100 public photos...
  File.open(p.filename, 'w') do |f|
    f.puts p.file('Square')                   # ...and save a local copy of their square thumbnail
  end
end

Searching:
#See http://www.flickr.com/services/api/flickr.photos.search.html for possible parameters
flickr = Flickr::Api.new('some_flickr_api_key') # create a flickr client (get an API key from http://www.flickr.com/services/api/)
photos = flickr.photos({"text" => "Guitar", "sort" => "relevance"})
photos.each {|photo| puts photo.title}

== REQUIREMENTS:

* Xmlsimple gem

== INSTALL:

Add this to your Gemfile:
gem 'agiley-flickr', :git => 'git://github.com/agiley/flickr.git', :branch => 'master', :require => 'flickr'

== LICENSE:

(The MIT License)

Copyright (c) 2008 Scott Raymond, Patrick Plattes, Chris Taggart

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.