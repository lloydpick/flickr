module Flickr
  class CommentCollection < Array
    # builds a CommentCollection from given params, such as those returned from 
    # photos.search API call. Note all the info is contained in the value of 
    # the first (and only) key-value pair of the response. The key will vary 
    # depending on the original object the photos are related to (e.g 'photos',
    # 'photoset', etc)
    def initialize(api_response={}, api_key=nil)
      comments = api_response["comments"]
      
      if (comments)
        collection = comments['comment'] || []
        collection = [collection] if collection.is_a? Hash
        collection.each { |comment| self << Comment.new(comment.delete('id'), api_key, comment) }
      end
    end
  end
end