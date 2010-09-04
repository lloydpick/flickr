module Flickr
  class Photo

    attr_reader :id, :client, :title

    def initialize(id=nil, api_key=nil, extra_params={})
      @id = id
      @api_key = api_key
      extra_params.each { |k,v| self.instance_variable_set("@#{k}", v) } # convert extra_params into instance variables
      @client = Flickr::Api.new @api_key
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

    def date_taken
      @date_taken.nil? ? getInfo("date_taken") : @date_taken
    end

    def title
      @title.nil? ? getInfo("title") : @title
    end

    # Returns the owner of the photo as a Flickr::User. If we have no info 
    # about the owner, we make an API call to get it. If we already have
    # the owner's id, create a user based on that. Either way, we cache the
    # result so we don't need to check again
    def owner
      case @owner
      when Flickr::User
        @owner
      when String
        @owner = Flickr::User.new(@owner, nil, nil, nil, @api_key)
      else
        getInfo("owner")
      end
    end

    def server
      @server.nil? ? getInfo("server") : @server
    end

    def isfavorite
      @isfavorite.nil? ? getInfo("isfavorite") : @isfavorite
    end

    def license
      @license.nil? ? getInfo("license") : @license
    end

    def rotation
      @rotation.nil? ? getInfo("rotation") : @rotation
    end

    def description
      @description || getInfo("description")
    end

    def notes
      @notes.nil? ? getInfo("notes") : @notes
    end

    # Returns the URL for the photo size page
    # defaults to 'Medium'
    # other valid sizes are in the VALID_SIZES hash
    def size_url(size='Medium')
      uri_for_photo_from_self(size) || sizes(size)['url']
    end

    # converts string or symbol size to a capitalized string
    def normalize_size(size)
      size ? size.to_s.capitalize : size
    end

    # the URL for the main photo page
    # if getInfo has already been called, this will return the pretty url
    #
    # for historical reasons, an optional size can be given
    # 'Medium' returns the regular url; any other size returns a size page
    # use size_url instead
    def url(size = nil)
      if normalize_size(size) != 'Medium'
        size_url(size)
      else
        @url || uri_for_photo_from_self
      end
    end

    # the 'pretty' url for a photo
    # (if the user has set up a custom name)
    # eg, http://flickr.com/photos/granth/2584402507/ instead of
    #     http://flickr.com/photos/23386158@N00/2584402507/
    def pretty_url
      @url || getInfo("pretty_url")
    end

    # Returns the URL for the image (default or any specified size)
    def source(size='Medium')
      image_source_uri_from_self(size) || sizes(size)['source']
    end

    # Returns the photo file data itself, in any specified size. Example: File.open(photo.title, 'w') { |f| f.puts photo.file }
    def file(size='Medium')
      Net::HTTP.get_response(URI.parse(source(size))).body
    end

    # Unique filename for the image, based on the Flickr NSID
    def filename
      "#{@id}.jpg"
    end

    # Implements flickr.photos.getContext
    def context
      context = @client.photos_getContext('photo_id'=>@id)
      @previousPhoto = Photo.new(context['prevphoto'].delete('id'), @api_key, context['prevphoto']) if context['prevphoto']['id']!='0'
      @nextPhoto = Photo.new(context['nextphoto'].delete('id'), @api_key, context['nextphoto']) if context['nextphoto']['id']!='0'
      return [@previousPhoto, @nextPhoto]
    end

    # Implements flickr.photos.getExif
    def exif
      @client.photos_getExif('photo_id'=>@id)['photo']
    end

    # Implements flickr.photos.getPerms
    def permissions
      @client.photos_getPerms('photo_id'=>@id)['perms']
    end

    # Implements flickr.photos.getSizes
    def sizes(size=nil)
      size = normalize_size(size)
      sizes = @client.photos_getSizes('photo_id'=>@id)['sizes']['size']
      sizes = sizes.find{|asize| asize['label']==size} if size
      return sizes
    end

    def vertical?
      @medium_size ||= self.sizes('Medium')
      @medium_size['height'] > @medium_size['width']
    end

    # flickr.tags.getListPhoto
    def tags
      @client.tags_getListPhoto('photo_id'=>@id)['photo']['tags']
    end

    # Implements flickr.photos.notes.add
    def add_note(note)
    end

    # Implements flickr.photos.setDates
    def dates=(dates)
    end

    # Implements flickr.photos.setPerms
    def perms=(perms)
    end

    # Implements flickr.photos.setTags
    def tags=(tags)
    end

    # Implements flickr.photos.setMeta
    def title=(title)
    end
    def description=(title)
    end

    # Implements flickr.photos.addTags
    def add_tag(tag)
    end

    # Implements flickr.photos.removeTag
    def remove_tag(tag)
    end

    # Implements flickr.photos.transform.rotate
    def rotate
    end

    # Implements flickr.blogs.postPhoto
    def postToBlog(blog_id, title='', description='')
      @client.blogs_postPhoto('photo_id'=>@id, 'title'=>title, 'description'=>description)
    end

    # Implements flickr.photos.notes.delete
    def deleteNote(note_id)
    end

    # Implements flickr.photos.notes.edit
    def editNote(note_id)
    end

    # Converts the Photo to a string by returning its title
    def to_s
      title
    end

    private

      # Implements flickr.photos.getInfo
      def getInfo(attrib="")
        return instance_variable_get("@#{attrib}") if @got_info
        info = @client.photos_getInfo('photo_id'=>@id)['photo']
        @got_info = true
        info.each { |k,v| instance_variable_set("@#{k}", v)}
        instance_variable_set("@date_taken", info['dates']['taken']) if (info['dates'] && info['dates']['taken'])
        @owner = User.new(info['owner']['nsid'], info['owner']['username'], nil, nil, @api_key)
        @tags = info['tags']['tag']
        @notes = info['notes']['note']#.collect { |note| Note.new(note.id) }
        @url = info['urls']['url']['content'] # assumes only one url
        instance_variable_get("@#{attrib}")
      end

      # Builds source uri of image from params (often returned from other 
      # methods, e.g. User#photos). As specified at: 
      # http://www.flickr.com/services/api/misc.urls.html. If size is given 
      # should be one the keys in the VALID_SIZES hash, i.e.
      # "Square", "Thumbnail", "Medium", "Large", "Original", "Small" (These
      # are the values returned by flickr.photos.getSizes).
      # If no size is given the uri for "Medium"-size image, i.e. with width
      # of 500 is returned
      # TODO: Handle "Original" size
      def image_source_uri_from_self(size=nil)
        return unless @farm&&@server&&@id&&@secret
        s_size = VALID_SIZES[normalize_size(size)] # get the short letters array corresponding to the size
        s_size = s_size&&s_size[0] # the first element of this array is used to build the source uri
        if s_size.nil?
          "http://farm#{@farm}.static.flickr.com/#{@server}/#{@id}_#{@secret}.jpg"
        else
          "http://farm#{@farm}.static.flickr.com/#{@server}/#{@id}_#{@secret}_#{s_size}.jpg"
        end
      end

      # Builds uri of Flickr page for photo. By default returns the main 
      # page for the photo, but if passed a size will return the simplified
      # flickr page featuring the given size of the photo
      # TODO: Handle "Original" size
      def uri_for_photo_from_self(size=nil)
        return unless @owner&&@id
        size = normalize_size(size)
        s_size = VALID_SIZES[size] # get the short letters array corresponding to the size
        s_size = s_size&&s_size[1] # the second element of this array is used to build the uri of the flickr page for this size
        "http://www.flickr.com/photos/#{owner.id}/#{@id}" + (s_size ? "/sizes/#{s_size}/" : "")
      end
  end
end