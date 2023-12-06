# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class AmazonS3BucketCreateV1

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

    @enable_debug_logging = @info_values['enable_debug_logging'].downcase == 'yes' ||
                            @info_values['enable_debug_logging'].downcase == 'true'
    puts "Parameters: #{@parameters.inspect}" if @enable_debug_logging

    @region = !@info_values["region"].to_s.empty? ? @info_values["region"] : @parameters["region"]
  end

  def execute()

    # Setup AWS client
    client = Aws::S3::Client.new(access_key_id: @info_values['access_key'],
      secret_access_key: @info_values['secret_key'],
      region: @region)

    # Parse object lock param into a boolean from a string
    object_lock_param = @parameters['object_lock_enabled_for_bucket'].to_s.downcase == 'yes' ||
                        @parameters['object_lock_enabled_for_bucket'].to_s.downcase == 'true'

    # Create Bucket see https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/S3/Client.html#create_bucket-instance_method
    resp = client.create_bucket({
      bucket: @parameters['bucket'],
      acl: (@parameters['acl'] if !@parameters['acl'].to_s.empty?),
      grant_full_control: (@parameters['grant_full_control'] if !@parameters['grant_full_control'].to_s.empty?),
      grant_read: (@parameters['grant_read'] if !@parameters['grant_read'].to_s.empty?),
      grant_read_acp: (@parameters['grant_read_acp'] if !@parameters['grant_read_acp'].to_s.empty?),
      grant_write: (@parameters['grant_write'] if !@parameters['grant_write'].to_s.empty?),
      grant_write_acp: (@parameters['grant_write_acp'] if !@parameters['grant_write_acp'].to_s.empty?),
      object_lock_enabled_for_bucket: (object_lock_param if !@parameters['object_lock_enabled_for_bucket'].to_s.empty?)
    })

    # Build the results XML that will be returned by this handler.
    <<-RESULTS
      <results>
          <result name="Location">#{escape(resp.location)}</result>
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