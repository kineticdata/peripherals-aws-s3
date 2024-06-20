# Require the necessary standard libraries
require 'rexml/document'

# If the Kinetic Task version is under 4, load the openssl and json libraries
# because they are not included in the ruby version
if KineticTask::VERSION.split('.').first.to_i < 4
    # Load the JRuby Open SSL library unless it has already been loaded.  This
    # prevents multiple handlers using the same library from causing problems.
    if not defined?(Jopenssl)
      # Load the Bouncy Castle library unless it has already been loaded.  This
      # prevents multiple handlers using the same library from causing problems.
      # Calculate the location of this file
      handler_path = File.expand_path(File.dirname(__FILE__))
      # Calculate the location of our library and add it to the Ruby load path
      library_path = File.join(handler_path, 'vendor/bouncy-castle-java-1.5.0147/lib')
      $:.unshift library_path
      # Require the library
      require 'bouncy-castle-java'


      # Calculate the location of this file
      handler_path = File.expand_path(File.dirname(__FILE__))
      # Calculate the location of our library and add it to the Ruby load path
      library_path = File.join(handler_path, 'vendor/jruby-openssl-0.8.8/lib/shared')
      $:.unshift library_path
      # Require the library
      require 'openssl'
      # Require the version constant
      require 'jopenssl/version'
    end

    # Validate the the loaded openssl library is the library that is expected for
    # this handler to execute properly.
    if not defined?(Jopenssl::Version::VERSION)
      raise "The Jopenssl class does not define the expected VERSION constant."
    elsif Jopenssl::Version::VERSION != '0.8.8'
      raise "Incompatible library version #{Jopenssl::Version::VERSION} for Jopenssl.  Expecting version 0.8.8"
    end




    # Load the ruby JSON library unless it has already been loaded.  This prevents
    # multiple handlers using the same library from causing problems.
    if not defined?(JSON)
      # Calculate the location of this file
      handler_path = File.expand_path(File.dirname(__FILE__))
      # Calculate the location of our library and add it to the Ruby load path
      library_path = File.join(handler_path, 'vendor/json-1.8.0/lib')
      $:.unshift library_path
      # Require the library
      require 'json'
    end

    # Validate the the loaded JSON library is the library that is expected for
    # this handler to execute properly.
    if not defined?(JSON::VERSION)
      raise "The JSON class does not define the expected VERSION constant."
    elsif JSON::VERSION != '1.8.0'
      raise "Incompatible library version #{JSON::VERSION} for JSON.  Expecting version 1.8.0."
    end
end




# Load the JMESPath library unless it has already been loaded.  This prevents
# multiple handlers using the same library from causing problems.
if not defined?(JMESPath)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/jmespath-1.1.3/lib')
  $:.unshift library_path
  # Require the library
  require 'jmespath'
end

# Validate the the loaded JSON library is the library that is expected for
# this handler to execute properly.
if not defined?(JMESPath::VERSION)
  raise "The JMESPath class does not define the expected VERSION constant."
elsif JMESPath::VERSION != '1.1.3'
  raise "Incompatible library version #{JMESPath::VERSION} for JMESPath.  Expecting version 1.1.3."
end

# Load the Amazon Web Services library unless it has already been loaded. This
# prevents multiple handlers using the same library from causing problems. 
if not defined?(Aws)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/aws-eventstream-1.1.1/lib')
  $:.unshift library_path
  # Require the library
  require 'aws-eventstream'

  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/aws-sigv4-1.2.3/lib')
  $:.unshift library_path
  # Require the library
  require 'aws-sigv4'
  
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/aws-partitions-1.465.0/lib')
  $:.unshift library_path
  # Require the library
  require 'aws-partitions'
 
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/aws-sdk-core-3.114.1/lib')
  $:.unshift library_path
  # Require the library
  require 'aws-sdk-core'

  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/aws-sdk-resources-3.104.0/lib')
  $:.unshift library_path
  # Require the library
  require 'aws-sdk-resources'

  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/aws-sdk-3.0.2/lib')
  $:.unshift library_path
  # Require the library
  require 'aws-sdk'
end

# Load the ruby Amazone S3 library unless it has already been loaded.  This prevents
# multiple handlers using the same library from causing problems.
if not defined?(Aws::S3)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/aws-sdk-kms-1.43.0/lib')
  $:.unshift library_path
  # Require the library
  require 'aws-sdk-kms'

  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/aws-sdk-s3-1.95.1/lib')
  $:.unshift library_path
  # Require the library
  require 'aws-sdk-s3'
end

handler_path = File.expand_path(File.dirname(__FILE__))

# Validate the the loaded AWS library is the library that is expected for
# this handler to execute properly.
if (!File.file?("#{handler_path}/vendor/aws-sdk-3.0.2/VERSION"))
  raise "The AWS gem does not have the expected VERSION file."
else
  version = File.read("#{handler_path}/vendor/aws-sdk-3.0.2/VERSION")

  if version.strip() != '3.0.2'
    raise "Incompatible library version #{version} for AWS.  Expecting version 3.0.2."
  end
end