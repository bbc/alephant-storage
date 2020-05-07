require "spec_helper"
require "date"

describe Alephant::Storage do
  let(:bucket)   { 'my-bucket' }
  let(:key) { 'my-key' }
  let(:path) { :path }
  let(:data) { 'data' }
  let(:fake_client) { Aws::S3::Client.new(stub_responses: true) }
  subject { Alephant::Storage.new(bucket, path) }

  before do
    allow(subject).to receive(:client).and_return(fake_client)
  end

  describe "override" do
    it "defaults to false" do
      expect(subject.send(:override_host_path?)).to eq(false)
    end
    it "is true if variable is set" do
      allow(ENV).to receive(:[]).with("AWS_S3_HOST_OVERRIDE").and_return("true")
      expect(subject.send(:override_host_path?)).to eq(true)
    end
  end

  describe "#initialize" do
    it "sets and exposes bucket, path instance variables " do
      expect(subject.bucket).to eq(bucket)
      expect(subject.path).to eq(path)
    end
  end

  describe "#clear" do
    before do
      fake_client.stub_responses(:list_objects, contents: fake_objects)
    end

    context 'with objects' do
      let(:fake_objects) { [ { key: key } ] }

      it 'deletes all objects for a path' do
        expect(subject.clear.data).to be_a(Aws::S3::Types::DeleteObjectsOutput)
      end
    end

    context 'with no objects' do
      let(:fake_objects) { [] }

      it 'returns DeleteObjectsOutput response' do
        expect(subject.clear.data).to be_a(Aws::S3::Types::DeleteObjectsOutput)
      end
    end
  end

  describe "#put" do
    it "sets bucket path/key content data" do
      expect(subject.put(key, data, 'foo/bar').data).to be_a(Aws::S3::Types::PutObjectOutput)
    end
  end

  describe "#get" do
    context 'with object response' do
      before do
        fake_client.stub_responses(:get_object, {
          body: 'content',
          etag: 'foo_123',
          metadata: meta,
          content_type: content_type,
          last_modified: Time.parse(last_modified)
        })
      end

      context 'with meta' do
        let(:meta) do
          {
            'foo' => 'bar'
          }
        end

        let(:content_type) { 'foo/bar' }
        let(:last_modified) { '2016-04-11 10:39:57 +0000' }

        it "gets bucket path/key content data" do
          expected_hash = {
            :content      => "content",
            :content_type => "foo/bar",
            :meta         => {
              :foo                  => 'bar',
              :head_ETag            => "foo_123",
              :"head_Last-Modified" => "Mon, 11 Apr 2016 10:39:57 GMT"
            }
          }

          expect(subject.get(key)).to eq(expected_hash)
        end
      end

      context 'with no meta' do
        let(:meta) { {} }

        let(:content_type) { 'foo/bar' }
        let(:last_modified) { '2016-04-11 10:39:57 +0000' }

        it "gets bucket path/key content data" do
          expected_hash = {
            :content      => "content",
            :content_type => "foo/bar",
            :meta         => {
              :head_ETag            => "foo_123",
              :"head_Last-Modified" => "Mon, 11 Apr 2016 10:39:57 GMT"
            }
          }

          expect(subject.get(key)).to eq(expected_hash)
        end
      end
    end

    context 'object does not exist' do
      before do
        fake_client.stub_responses(:get_object, 'NoSuchKey')
      end

      it 'raises NoSuchKey' do
        expect { subject.get(key) }.to raise_error(Aws::S3::Errors::NoSuchKey)
      end
    end

    context 'bucket does not exist' do
      before do
        fake_client.stub_responses(:get_object, 'NoSuchBucket')
      end

      it 'raises NoSuchBucket' do
        expect { subject.get(key) }.to raise_error(Aws::S3::Errors::NoSuchBucket)
      end
    end
  end
end
