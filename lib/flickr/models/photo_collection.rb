# A collection of photos is returned as a PhotoCollection, a subclass of Array.
# This allows us to retain the pagination info returned by Flickr and make it
# accessible in a friendly way
module Flickr
  class PhotoCollection < Array
    attr_reader :page, :pages, :perpage, :total

    # builds a PhotoCollection from given params, such as those returned from 
    # photos.search API call. Note all the info is contained in the value of 
    # the first (and only) key-value pair of the response. The key will vary 
    # depending on the original object the photos are related to (e.g 'photos',
    # 'photoset', etc)
    def initialize(photos_api_response={}, api_key=nil)
      photos = photos_api_response["photos"]
      photos = (photos) ? photos : photos_api_response["photoset"]
      
      if (photos)
        [ "page", "pages", "perpage", "total" ].each { |i| instance_variable_set("@#{i}", photos[i])} 
        collection = photos['photo'] || []
        collection = [collection] if collection.is_a? Hash
        collection.each { |photo| self << Photo.new(photo.delete('id'), api_key, photo) }
      end
    end
  end
end