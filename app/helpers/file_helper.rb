# Helper methods for file views
module FileHelper
  # Replace 'myfile' with 'file' in a message
  def myfile_to_file(msg)
    return msg.sub('myfile', 'file') if msg
  end
  
  def s3_policy( opts )
    # opts[:key] - file upload name prefix - only allows uploads of files which start with this string
    # opts[:max_filesize] - the maximum filesize
    
    bucket = CONFIG[:paperclip][:bucket]
    access_key = CONFIG[:paperclip][:s3_credentials][:access_key_id]
    secret = CONFIG[:paperclip][:s3_credentials][:secret_access_key]
    key = opts[:key] || "uploads/#{ActiveSupport::SecureRandom.hex(8)}/"
    expiration = 10.hours.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')
    max_filesize = opts[:max_filesize] || 30.megabytes
    sas = '201' # Tells amazon to redirect after success instead of returning xml
    policy = Base64.encode64(
      "{'expiration': '#{expiration}',
        'conditions': [
          {'bucket': '#{bucket}'},
          ['starts-with', '$key', '#{key}'],
          {'success_action_status': '#{sas}'},
          ['content-length-range', 1, #{max_filesize}],
          ['starts-with', '$filename', ''],
          ['starts-with', '$folder', ''],
          ['starts-with', '$fileext', '']
        ]}
      ").gsub(/\n|\r/, '')
    signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), secret, policy)).gsub(/\n| |\r/, '')
    {:access_key => access_key, :key => key, :policy => policy, :signature => signature, :sas => sas, :bucket => bucket, :max_filesize => max_filesize}
  end
  
  def s3_bucket
    "http://#{CONFIG[:paperclip][:bucket]}.s3.amazonaws.com/"
  end
  
  def s3_data( policy )
    "{ 'AWSAccessKeyId' : encodeURIComponent(encodeURIComponent('#{policy[:access_key]}')),
       'key': encodeURIComponent(encodeURIComponent('#{policy[:key]}${filename}')),
       'policy': encodeURIComponent(encodeURIComponent('#{policy[:policy]}')),
       'signature': encodeURIComponent(encodeURIComponent('#{policy[:signature]}')),
       'success_action_status': '#{policy[:sas]}',
       'folder': '',
       'Filename': '' };"
  end
  
  def uploadify_s3( opts )
    policy = opts[:policy] || s3_policy
    
    javascript_tag "$('#{opts[:selector] || '#uploadify_source'}').uploadify({
      'uploader'        : '#{opts[:uploader]      || '/flash/uploadify.swf'}',
      'buttonImg'       : '#{opts[:button_img]    || '/images/upload.png'}',
      'cancelImg'       : '#{opts[:cancel_img]    || '/images/cancel.png'}',
      
      'scriptAccess'    : '#{opts[:script_access] || 'always'}',
      'queueID'         : '#{opts[:queue_id]      || 'uploadifyQueue'}',
      
      'fileDataName'    : '#{opts[:file]          || 'file'}',
      'fileDesc'        : '#{opts[:file_desc]}',
      'fileExt'         : '#{opts[:file_ext]}',
      'folder'          : '#{opts[:folder]}',

      'auto'            : #{opts[:auto]           || 'true'},
      'multi'           : #{opts[:multi]          || 'true'}
                              
      'script'          : '#{policy[:bucket]}',
      'sizeLimit'       : #{policy[:max_filesize]},
      
      'scriptData'      : #{s3_data(policy)},

      'onComplete'      : #{opts[:on_complete]},
      'onError'         : #{opts[:on_error]},
    });"
  end
end
