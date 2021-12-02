# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class AmazonS3FileUploadFromSubmissionV2

  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)

    # Store the info values in a Hash of info names to values.
    @info_values = {}
    REXML::XPath.each(@input_document,"/handler/infos/info") { |item|
      @info_values[item.attributes['name']] = item.text
    }

    # Retrieve all of the handler parameters and store them in a hash attribute
    # named @parameters.
    @parameters = {}
    REXML::XPath.match(@input_document, 'handler/parameters/parameter').each do |node|
      @parameters[node.attribute('name').value] = node.text.to_s
    end

    @debug_logging_enabled = ["yes","true"].include?(@info_values['enable_debug_logging'].downcase)
    puts "Parameters: #{@parameters.inspect}" if @debug_logging_enabled

    @region = !@info_values["region"].to_s.empty? ? @info_values["region"] : @parameters["region"]
  end

  def execute()

    begin
      # Configure the S3 client
      s3 = Aws::S3::Client.new(access_key_id: @info_values['access_key'],
        secret_access_key: @info_values['secret_key'],
        region: @region)
      bucket = Aws::S3::Bucket.new(@parameters['bucket'], {client: s3})

      # Get the attachment info from the submission object
      space_slug = @parameters["space_slug"].empty? ?
        @info_values["space_slug"] :
        @parameters["space_slug"]
      api_route = "#{@info_values["request_ce_server"]}"+
        "#{!space_slug.to_s.empty? ? "/#{space_slug}" : ""}/app/api/v1/submissions"
      
      submission_api_route = "#{api_route}/#{URI.escape(@parameters['submission_id'])}?include=values"

      puts "Submission API route: #{submission_api_route}" if @debug_logging_enabled

      submission = RestClient::Resource.new(submission_api_route,
        :user => @info_values['request_ce_username'], 
        :password => @info_values['request_ce_password']).get
      field = JSON.parse(submission)["submission"]["values"][@parameters["field"]]

      return "<results><results name=\"Public Url\"></result></results>" if field.empty?

      # Download the attachment from Request CE/Filehub
      download_api_route = "#{api_route}/#{URI.escape(@parameters['submission_id'])}/files/"+
        "#{URI.escape(@parameters['field'])}/0/#{URI.escape(field[0]['name'])}/url"
      
      puts "Download API route: #{download_api_route}" if @debug_logging_enabled

      download_url = JSON.parse(RestClient::Resource.new(download_api_route,
        :user => @info_values['request_ce_username'], 
        :password => @info_values['request_ce_password']).get)["url"]
        
      puts "Asset URL: #{download_url}" if @debug_logging_enabled

      file_name = @parameters['file_name'].empty? ?
        field[0]['name'] :
        @parameters['file_name']

      upload_path = @parameters['upload_path'].empty? ?
      file_name :
      "#{@parameters['upload_path']}#{file_name}"

      puts "S3 upload Path for asset: #{upload_path}" if @debug_logging_enabled

      object = bucket.object(upload_path)
      object.put(
        acl: 'public-read', 
        body: RestClient::Resource.new(download_url,
          :user => @info_values['request_ce_username'], 
          :password => @info_values['request_ce_password']).get
      )
      public_url = object.public_url
    rescue RestClient::Exception => e
      raise e
    end
    # Build the results XML that will be returned by this handler.
    <<-RESULTS
      <results>
          <result name="Public Url">#{escape(public_url)}</result>
      </results>
    RESULTS
  end

  ##############################################################################
  # General handler utility functions
  ##############################################################################

  # This is a template method that is used to escape results values (returned in
  # execute) that would cause the XML to be invalid.  This method is not
  # necessary if values do not contain character that have special meaning in
  # XML (&, ", <, and >), however it is a good practice to use it for all return
  # variable results in case the value could include one of those characters in
  # the future.  This method can be copied and reused between handlers.
  def escape(string)
    # Globally replace characters based on the ESCAPE_CHARACTERS constant
    string.to_s.gsub(/[&"><]/) { |special| ESCAPE_CHARACTERS[special] } if string
  end
  # This is a ruby constant that is used by the escape method
  ESCAPE_CHARACTERS = {'&'=>'&amp;', '>'=>'&gt;', '<'=>'&lt;', '"' => '&quot;'}
end