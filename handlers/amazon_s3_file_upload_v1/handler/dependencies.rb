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



# NOTE: If looking for version 1 of the Aws gem, use the module name AWS. The
# different capitalization allows for v1 and v2 to be used in the same file.

# Load the Amazon Web Services library unless it has already been loaded. This
# prevents multiple handlers using the same library from causing problems. This
# library only uses one module/version but is packaged up using 3 different gems,
# so all three will be loaded up if Aws is not defined.
if not defined?(Aws)
  # Calculate the location of this file
  handler_path = File.expand_path(File.dirname(__FILE__))
  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/aws-sdk-core-2.2.34/lib')
  $:.unshift library_path
  # Require the library
  require 'aws-sdk-core'

  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/aws-sdk-resources-2.2.34/lib')
  $:.unshift library_path
  # Require the library
  require 'aws-sdk-resources'

  # Calculate the location of our library and add it to the Ruby load path
  library_path = File.join(handler_path, 'vendor/aws-sdk-2.2.34/lib')
  $:.unshift library_path
  # Require the library
  require 'aws-sdk'
end

# Validate the the loaded AWS library is the library that is expected for
# this handler to execute properly.
if not defined?(Aws::VERSION)
  raise "The AWS gem does not define the expected VERSION constant."
elsif Aws::VERSION != '2.2.34'
  raise "Incompatible library version #{Aws::VERSION} for AWS.  Expecting version 2.2.34."
end
