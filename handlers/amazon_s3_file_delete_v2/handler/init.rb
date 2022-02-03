# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class AmazonS3FileDeleteV2

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

    @enable_debug_logging = 
      @info_values['enable_debug_logging'].downcase == 'yes' || 
      @info_values['enable_debug_logging'].downcase == 'true'
    puts "Parameters: #{@parameters.inspect}" if @enable_debug_logging

    @region = !@info_values["region"].to_s.empty? ? 
      @info_values["region"] : 
      @parameters["region"]
  end

  def execute()
    # Configure the S3 client
    s3 = Aws::S3::Client.new(
      access_key_id: @info_values['access_key'],
      secret_access_key: @info_values['secret_key'],
      region: @region
    )
    
    # Get list of files to delete
    object_keys = @parameters['object_keys'].split(',')
    puts "Object keys: #{object_keys}" if @enable_debug_logging
    delete_objects = Array.new
    object_keys.each { |object_key|
      delete_objects.push({key: object_key})
    }

    puts "Deleting S3 assets from #{@parameters['bucket']}" if @enable_debug_logging

    # Delete files from s3 bucket
    bucket = Aws::S3::Bucket.new(@parameters['bucket'], {client: s3})
    response = bucket.delete_objects({
      delete: {
        objects: delete_objects,
      }
    })
  
    # Build the results XML that will be returned by this handler.
    <<-RESULTS
      <results>
          <result name="Results">#{escape(response.to_h.to_json)}</result>
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