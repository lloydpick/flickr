# Todo:
# flickr.photosets.delete
# flickr.photosets.editMeta
# flickr.photosets.editPhotos
# flickr.photosets.getContext
# flickr.photosets.getInfo
# flickr.photosets.getPhotos
module Flickr
  class Photoset

    attr_reader :id, :client, :owner, :primary, :photos, :title, :description, :url

    def initialize(id=nil, api_key=nil)
      @id = id
      @api_key = api_key
      @client = Flickr::Api.new @api_key
    end

    def owner
      @owner || getInfo.owner
    end

    def primary
      @primary || getInfo.primary
    end

    def title
      @title || getInfo.title
    end

  	def url
      @url || getInfo.url
    end

  	def photos
  		@photos ||= getPhotos
    end

  	def first_photo
  		@first_photo ||= getFirstPhoto
    end

    private
    def getInfo
      unless @info
        @info = @client.photosets_getInfo('photoset_id'=>@id)['photoset']
        @owner = User.new(@info['owner'], nil, nil, nil, @api_key)
        @primary = @info['primary']
        @title = @info['title']
        @description = @info['description']
        @url = "#{@owner.photos_url}sets/#{@id}/"
      end
      self
    end

    def getPhotos
      @client.photos_request('photosets.getPhotos', {'photoset_id' => @id})
    end

    def getFirstPhoto
      @client.photos_request('photosets.getPhotos', {'photoset_id' => @id, :per_page => 1}).first
    end
  end
end