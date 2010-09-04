# = Flickr
#   An insanely easy interface to the Flickr photo-sharing service. By Scott Raymond.
#   
# Author::    Scott Raymond <sco@redgreenblu.com>
# Copyright:: Copyright (c) 2005 Scott Raymond <sco@redgreenblu.com>. Additional content by Patrick Plattes and Chris Taggart (http://pushrod.wordpress.com)
# License::   MIT <http://www.opensource.org/licenses/mit-license.php>
#
# BASIC USAGE:
#  require 'flickr'
#  flickr = Flickr::Api.new('some_flickr_api_key')    # create a flickr client (get an API key from http://www.flickr.com/services/api/)
#  user = flickr.users('sco@scottraymond.net')   # lookup a user
#  user.name                                     # get the user's name
#  user.location                                 # and location
#  user.photos                                   # grab their collection of Photo objects...
#  user.groups                                   # ...the groups they're in...
#  user.contacts                                 # ...their contacts...
#  user.favorites                                # ...favorite photos...
#  user.photosets                                # ...their photo sets...
#  user.tags                                     # ...and their tags
#  recentphotos = flickr.photos                  # get the 100 most recent public photos
#  photo = recentphotos.first                    # or very most recent one
#  photo.url                                     # see its URL,
#  photo.title                                   # title,
#  photo.description                             # and description,
#  photo.owner                                   # and its owner.
#  File.open(photo.filename, 'w') do |file|
#    file.puts p.file                            # save the photo to a local file
#  end
#  flickr.photos.each do |p|                     # get the last 100 public photos...
#    File.open(p.filename, 'w') do |f|
#      f.puts p.file('Square')                   # ...and save a local copy of their square thumbnail
#    end
#  end


require 'cgi'
require 'net/http'
require 'xmlsimple' unless defined? XmlSimple
require 'digest/md5'
require File.expand_path(File.dirname(__FILE__) + '/flickr/api')
require File.expand_path(File.dirname(__FILE__) + '/flickr/models/group')
require File.expand_path(File.dirname(__FILE__) + '/flickr/models/photo')
require File.expand_path(File.dirname(__FILE__) + '/flickr/models/photo_collection')
require File.expand_path(File.dirname(__FILE__) + '/flickr/models/photoset')
require File.expand_path(File.dirname(__FILE__) + '/flickr/models/user')

module Flickr
  #The API implementation is found in /flickr/api
  
  # Flickr, annoyingly, uses a number of representations to specify the size 
  # of a photo, depending on the context. It gives a label such a "Small" or
  # "Medium" to a size of photo, when returning all possible sizes. However, 
  # when generating the uri for the page that features that size of photo, or
  # the source url for the image itself it uses a single letter. Bizarrely, 
  # these letters are different depending on whether you want the Flickr page
  # for the photo or the source uri -- e.g. a "Small" photo (240 pixels on its
  # longest side) may be viewed at 
  # "http://www.flickr.com/photos/sco/2397458775/sizes/s/"
  # but its source is at 
  # "http://farm4.static.flickr.com/3118/2397458775_2ec2ddc324_m.jpg". 
  # The VALID_SIZES hash associates the correct letter with a label
  VALID_SIZES = { "Square" => ["s", "sq"],
                  "Thumbnail" => ["t", "t"],
                  "Small" => ["m", "s"],
                  "Medium" => [nil, "m"],
                  "Large" => ["b", "l"]
                }
end