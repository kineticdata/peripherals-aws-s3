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

    @region = !@info_values["region"].to_s.empty? ? 
      @info_values["region"] : 
      @parameters["region"]
  end

  def execute()    
    # Set space slug base on inputs
    space_slug = @parameters["space_slug"].empty? ? 
      @info_values["space_slug"] : 
      @parameters["space_slug"]
    if @info_values['request_ce_server'].include?("${space}")
      source_server = @info_values['request_ce_server'].gsub("${space}", space_slug)
    elsif !space_slug.to_s.empty?
      source_server = @info_values['request_ce_server']+"/"+space_slug
    else
      source_server = @info_values['request_ce_server']
    end

    # Configure the S3 client
    s3 = Aws::S3::Client.new(
      access_key_id: @info_values['access_key'],
      secret_access_key: @info_values['secret_key'],
      region: @region
    )
    bucket = Aws::S3::Bucket.new(@parameters['bucket'], {client: s3})

    #Source Variables
    source_username = @info_values['request_ce_username']
    source_password = @info_values['request_ce_password']
    attachment_field = @parameters["field"]
    submission_id = @parameters['submission_id']
    #Destination Variables
    upload_path = @parameters['upload_path']
    acl = @parameters['acl'].empty? ? 'public-read' : @parameters['acl']

    submission_api_route = "#{source_server}/app/api/v1/submissions/#{submission_id}?include=values"
    puts "Submission API route: #{submission_api_route}" if @debug_logging_enabled

    # Headers for each server: Authorization, Accept, Content-Type
    source_headers = http_basic_headers(source_username, source_password)
    
    # Retrieve the submission and values
    res = http_get(submission_api_route, { "include" => "values" }, source_headers)
    if !res.kind_of?(Net::HTTPSuccess)
      message = "Failed to retrieve source submission #{submission_id}"
      return handle_exception(message, res)
    end
    submission = JSON.parse(res.body)["submission"]
    field = submission["values"][attachment_field]

    public_url = Array.new
    # If the attachment field value exists
    if !field.nil?
      # Attachment field values are stored as arrays, one map for each file attachment.
      #
      # This isn't the real attachment info though, this is just metadata about the attachment
      # that can be retrieved to get a link to the attachment in Filehub.
      #
      # Process each attachment file
      field.each_with_index do |attachment_info, index|
        begin
          # The attachment file name is stored in the 'name' property
          attachment_name = attachment_info['name']

          # Temporary file to stream contents to
          tempdir = "#{Dir.tmpdir}/#{SecureRandom.hex(8)}"
          tempfile = "#{tempdir}/#{attachment_name}"
          FileUtils.mkdir_p(tempdir)


          # Retrieve the attachment download link from the source server
          puts "Retrieving attachment download link from source submission: #{attachment_name} for field #{attachment_field}" if @enable_debug_logging

          # API route to get the generated attachment download link from Kinetic Request CE.
          download_link_api_route = "#{source_server}/app/api/v1" <<
            "/submissions/#{submission['id']}" <<
            "/files/#{URI.escape(attachment_field)}" <<
            "/#{index.to_s}/#{URI.escape(attachment_name)}/url"

          # Retrieve the URL to download the attachment from Kinetic Request CE.
          res = http_get(download_link_api_route, {}, source_headers)
          if !res.kind_of?(Net::HTTPSuccess)
            message = "Failed to retrieve link for attachment #{attachment_name} from source submission"
            return handle_exception(message, res)
          end
          file_download_url = JSON.parse(res.body)['url']
          puts "Received link for attachment #{attachment_name} from source submission" if @enable_debug_logging


          # Download the attachment from the source server
          puts "Downloading attachment #{attachment_name} from #{file_download_url}" if @enable_debug_logging
          res = stream_file_download(tempfile, file_download_url, {}, source_headers)
          if !res.kind_of?(Net::HTTPSuccess)
            message = "Failed to download attachment #{attachment_name} from the source server"
            return handle_exception(message, res)
          end
          puts "Attachment Name: #{attachment_name}"
          # Add a path to upload file to if provided
          destination_upload_path = upload_path.empty? ?
          attachment_name :
          "#{upload_path}#{attachment_name}"
    
          puts "S3 upload Path for asset: #{destination_upload_path}" if @debug_logging_enabled
          
          # Upload file to s3
          object = bucket.object(destination_upload_path)
          object.put(
            acl: acl, 
            body: File.open(tempfile)
          )

          # Collect the list of response urls
          public_url.push(object.public_url)
        ensure
          # Remove the temp directory along with the downloaded attachment
          FileUtils.rm_rf(tempdir)
        end
      end
      
    else
      puts "Submission attachment field value is empty on the source server: #{source_field_name}" if @enable_debug_logging
    end

    results = handle_results(public_url, "")
    puts "Returning results: #{results}" if @enable_debug_logging
    results
  end

  ##############################################################################
  # General handler utility functions
  ##############################################################################
  def handle_results(public_url, error_msg)
    <<-RESULTS
    <results>
      <result name="Handler Error Message">#{ERB::Util.html_escape(error_msg)}</result>
      <result name="Public Url">#{ERB::Util.html_escape(public_url)}</result>
    </results>
    RESULTS
  end

  def handle_exception(message, error)
    case error
    when Net::HTTPResponse
      begin
        content = JSON.parse(error.body)
        error_key = content["errorKey"] || error.code
        error_msg = content["error"] || ""
        error_message = "#{message}:\n\tError Key: #{error_key}\n\tError: #{error_msg}"
      rescue StandardError => e
        error_key = error.code
        error_message = "#{message}:\n\tError Key: #{error_key}\n\tError: #{error.body}"
      end
    when NilClass
      error_message = "0: No response from server"
    else
      error_message = "Unexpected error: #{error.inspect}"
    end
    puts error_message
    raise error_message if @raise_error
    handle_results(nil, error_message)
  end

  #-----------------------------------------------------------------------------
  # The following Http helper methods are provided within this handler because
  # task currently doesn't have a common http client module that handlers can
  # use. If these methods were packaged as a module within the dependencies.rb
  # file or within a gem/library, they would be under the same constraints as
  # other vendor gems, such as RestClient, where any handler that uses
  # RestClient is currently stuck using v1.6.7. Adding these methods
  # directly to the handler class gives the freedom to add/modify as needed
  # without affecting other handlers.
  #-----------------------------------------------------------------------------


  #-----------------------------------------------------------------------------
  # HTTP HEADERS
  #-----------------------------------------------------------------------------

  def http_json_headers
    {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
  end
  
  
  def http_basic_headers(username, password)
    http_json_headers.merge({
      "Authorization" => "Basic #{Base64.strict_encode64("#{username}:#{password}")}"
    })
  end

  #-----------------------------------------------------------------------------
  # REST ACTIONS
  #-----------------------------------------------------------------------------
  
  def http_get(url, parameters, headers, http_options={})
    uri = URI.parse(url)
    uri.query = URI.encode_www_form(parameters) unless parameters.empty?
    request = Net::HTTP::Get.new(uri, headers)
    send_request(request, http_options)
  end

  #-----------------------------------------------------------------------------
  # ATTACHMENT METHODS
  #-----------------------------------------------------------------------------

  def stream_file_download(file, url, parameters, headers, http_options={})
    uri = URI.parse(url)
    uri.query = URI.encode_www_form(parameters) unless parameters.empty?

    http = build_http(uri, http_options)
    request = Net::HTTP::Get.new(uri, headers)

    http.request(request) do |response|
      open(file, 'w') do |io|
        response.read_body do |chunk|
          io.write chunk
        end
      end
    end
  end


  #-----------------------------------------------------------------------------
  # LOWER LEVEL METHODS
  #-----------------------------------------------------------------------------

  def send_request(request, http_options={})
    uri = request.uri
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      configure_http(http, http_options)
      http.request(request)
    end
  end
  
  
  def build_http(uri, http_options={})
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl= true if (uri.scheme == 'https')
    configure_http(http, http_options)
    http
  end


  def configure_http(http, http_options={})
    http_options_sym = (http_options || {}).inject({}) { |h, (k,v)| h[k.to_sym] = v; h }
    http.verify_mode = http_options_sym[:ssl_verify] || OpenSSL::SSL::VERIFY_PEER if http.use_ssl?
    http.read_timeout= http_options_sym[:read_timeout] unless http_options_sym[:read_timeout].nil?
    http.open_timeout= http_options_sym[:open_timeout] unless http_options_sym[:open_timeout].nil?
  end
end