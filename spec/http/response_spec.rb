require 'spec_helper'

describe HTTP::Response do
  describe 'headers' do
    let(:body) { double(:body) }
    let(:headers) { {'Content-Type' => 'text/plain'} }

    subject(:response) { HTTP::Response.new(200, '1.1', headers, body) }

    it 'exposes header fields for easy access' do
      expect(response['Content-Type']).to eq('text/plain')
    end

    it 'provides a #headers accessor too' do
      expect(response.headers).to eq('Content-Type' => 'text/plain')
    end

    context 'with duplicate header keys (mixed case)' do
      let(:headers) { {'Set-Cookie' => 'a=1;', 'set-cookie' => 'b=2;'} }

      it 'groups values into Array' do
        expect(response['Set-Cookie']).to match_array ['a=1;', 'b=2;']
      end
    end
  end

  describe '#[]=' do
    let(:body) { double(:body) }
    let(:response) { HTTP::Response.new(200, '1.1', {}, body) }

    it 'normalizes header name' do
      response['set-cookie'] = 'foo=bar;'
      expect(response.headers).to eq('Set-Cookie' => 'foo=bar;')
    end

    it 'groups duplicate header values into Arrays' do
      response['set-cookie'] = 'a=b;'
      response['set-cookie'] = 'c=d;'
      response['set-cookie'] = 'e=f;'

      expect(response.headers).to eq('Set-Cookie' => ['a=b;', 'c=d;', 'e=f;'])
    end

    it 'respects if additional value is Array' do
      response['set-cookie'] = 'a=b;'
      response['set-cookie'] = ['c=d;', 'e=f;']

      expect(response.headers).to eq('Set-Cookie' => ['a=b;', 'c=d;', 'e=f;'])
    end
  end

  describe 'to_a' do
    let(:body)         { 'Hello world' }
    let(:content_type) { 'text/plain' }
    subject { HTTP::Response.new(200, '1.1', {'Content-Type' => content_type}, body) }

    it 'returns a Rack-like array' do
      expect(subject.to_a).to eq([200, {'Content-Type' => content_type}, body])
    end
  end

  describe 'mime_type' do
    subject { HTTP::Response.new(200, '1.1', headers, '').mime_type }

    context 'without Content-Type header' do
      let(:headers) { {} }
      it { should be_nil }
    end

    context 'with Content-Type: text/html' do
      let(:headers) { {'Content-Type' => 'text/html'} }
      it { should eq 'text/html' }
    end

    context 'with Content-Type: text/html; charset=utf-8' do
      let(:headers) { {'Content-Type' => 'text/html; charset=utf-8'} }
      it { should eq 'text/html' }
    end
  end

  describe 'charset' do
    subject { HTTP::Response.new(200, '1.1', headers, '').charset }

    context 'without Content-Type header' do
      let(:headers) { {} }
      it { should be_nil }
    end

    context 'with Content-Type: text/html' do
      let(:headers) { {'Content-Type' => 'text/html'} }
      it { should be_nil }
    end

    context 'with Content-Type: text/html; charset=utf-8' do
      let(:headers) { {'Content-Type' => 'text/html; charset=utf-8'} }
      it { should eq 'utf-8' }
    end
  end

  describe '#parse' do
    let(:headers)   { {'Content-Type' => content_type} }
    let(:body)      { '{"foo":"bar"}' }
    let(:response)  { HTTP::Response.new 200, '1.1', headers, body }

    context 'with known content type' do
      let(:content_type) { 'application/json' }
      it 'returns parsed body' do
        expect(response.parse).to eq 'foo' => 'bar'
      end
    end

    context 'with unknown content type' do
      let(:content_type) { 'application/deadbeef' }
      it 'raises HTTP::Error' do
        expect { response.parse }.to raise_error HTTP::Error
      end
    end

    context 'with explicitly given mime type' do
      let(:content_type) { 'application/deadbeef' }
      it 'ignores mime_type of response' do
        expect(response.parse 'application/json').to eq 'foo' => 'bar'
      end

      it 'supports MIME type aliases' do
        expect(response.parse :json).to eq 'foo' => 'bar'
      end
    end
  end
end
