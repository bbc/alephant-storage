require "alephant/storage/version"
require "alephant/logger"
require "aws-sdk-s3"
require "date"

module Alephant
  class Storage
    include Logger
    attr_reader :bucket, :path

    def initialize(bucket, path)
      @bucket = bucket
      @path   = path

      logger.info(
        "event"  => "StorageInitialized",
        "bucket" => bucket,
        "path"   => path,
        "method" => "#{self.class}#initialize"
      )
    end

    def clear
      logger.info(
        "event"  => "StorageCleared",
        "bucket" => bucket,
        "path"   => path,
        "method" => "#{self.class}#clear"
      )

      objects = client.list_objects(
        bucket: bucket,
        prefix: path
      )

      client.delete_objects(
        bucket: bucket,
        delete: {
          objects: objects.data.contents.map { |o| { key: o.key } }
        }
      )
    end

    def put(key, data, content_type = "text/plain", meta = {})
      logger.metric "StoragePuts"
      logger.info(
        "event"    => "StorageObjectStored",
        "bucket"   => bucket,
        "path"     => path,
        "key"      => key,
        "method"   => "#{self.class}#put"
      )

      client.put_object(
        bucket: bucket,
        body: data,
        key: [path, key].join('/'),
        content_type: content_type,
        metadata: meta
      )
    end

    def get(key)
      object = client.get_object(
        bucket: bucket,
        key: [path, key].join('/')
      )

      meta = object.metadata.merge(add_custom_meta(object))

      logger.metric "StorageGets"
      logger.info(
        "event"       => "StorageObjectRetrieved",
        "bucket"      => bucket,
        "path"        => path,
        "key"         => key,
        "contentType" => object.content_type,
        "metadata"    => meta,
        "method"      => "#{self.class}#get"
      )

      {
        :content      => object.body.read,
        :content_type => object.content_type,
        :meta         => Hash[meta.map { |k, v| [k.to_sym, v] }]
      }
    end

    private

    def add_custom_meta(object)
      {
        :head_ETag            => object.etag,
        :"head_Last-Modified" => DateTime.parse(object.last_modified.to_s).httpdate
      }
    end

    def override_host_path?
      ENV['AWS_S3_HOST_OVERRIDE'] == 'true'
    end


    def client
      options = {}
      options[:endpoint] = ENV['AWS_S3_ENDPOINT'] if ENV['AWS_S3_ENDPOINT']
      if override_host_path?
        options[:disable_host_prefix_injection] = true
        options[:force_path_style] = true
      end
      @client ||= ::Aws::S3::Client.new(options)
    end
  end
end
