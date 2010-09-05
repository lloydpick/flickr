module Flickr
  class Comment
    attr_reader :id, :client, :content, :permalink

    def initialize(id=nil, api_key=nil, extra_params={})
      @id = id
      @api_key = api_key
      extra_params.each { |k,v| self.instance_variable_set("@#{k}", v) } # convert extra_params into instance variables
    end

    # Allows access to all photos instance variables through hash like 
    # interface, e.g. photo["datetaken"] returns @datetaken instance 
    # variable. Useful for accessing any weird and wonderful parameter
    # that may have been returned by Flickr when finding the photo,
    # e.g. those returned by the extras argument in 
    # flickr.people.getPublicPhotos
    def [](param_name)
      instance_variable_get("@#{param_name}")
    end
    
    def author
      case @author
        when Flickr::User then @author
        when String then Flickr::User.new('id' => @author, 'username' => @authorname, 'api_key' => @api_key)
        else
          @author
      end
    end
    
  end
end