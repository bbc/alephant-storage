require 'alephant/storage/version'
require 'alephant/logger'
require 'aws-sdk'

module Alephant
  class Storage
    include Logger
    attr_reader :id, :bucket, :path

    def initialize(id, path)
      @id = id
      @path = path
      @bucket = AWS::S3.new.buckets[id]

      logger.info(
        "event"  => "StorageInitialized",
        "id"     => id,
        "path"   => path,
        "method" => "#{self.class}#initialize",
      )
    end

    def clear
      bucket.objects.with_prefix(path).delete_all
      logger.info(
        "event"  => "StorageCleared",
        "path"   => path,
        "method" => "#{self.class}#clear"
      )
    end

    def put(id, data, content_type = 'text/plain', meta = {})
      bucket.objects["#{path}/#{id}"].write(
        data,
        {
          :content_type => content_type,
          :metadata     => meta
        }
      )

      logger.metric "StoragePuts"
      logger.info(
        "event"  => "StorageObjectStored",
        "path"   => path,
        "id"     => id,
        "method" => "#{self.class}#put"
      )
    end

    def get(id)
      object       = bucket.objects["#{path}/#{id}"]
      content      = object.read
      content_type = object.content_type
      meta_data    = object.metadata.to_h.merge(add_custom_meta(object))

      logger.metric "StorageGets"
      logger.info(
        "event"       => "StorageObjectRetrieved",
        "path"        => path,
        "id"          => id,
        "contentType" => content_type,
        "metadata"    => meta_data,
        "method"      => "#{self.class}#get"
      )

      {
        :content      => content,
        :content_type => content_type,
        :meta         => meta_data
      }
    end

    private

    def add_custom_meta(object)
      {
        :head_ETag            => object.etag,
        :"head_Last-Modified" => object.last_modified
      }
    end
  end
end
