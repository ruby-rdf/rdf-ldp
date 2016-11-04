require 'rack/memento/link_format_builder'

describe Rack::Memento::LinkFormatBuilder do
  let(:original) { 'http://example.com/moomin' }
  let(:timegate) { 'http://example.com/moomin/.well-known/timegate' }
  let(:error)    { /^Can\'t build a.* link relation;/ }

  describe 'initializer' do
    it 'initializes empty' do
      expect(subject.original).to be_nil
    end
    
    context 'with parameters' do
      subject do
        described_class.new(original: original, 
                            timegate: timegate)
      end
      
      it 'sets instance variales' do
        expect(subject).to have_attributes(original: original,
                                           timegate: timegate)
      end
    end
  end

  describe '#build' do
    subject do
      described_class.new(original: original, 
                          timegate: timegate)
    end

    [:original, :timegate].each do |rel|
      it "builds full link format with #{rel}" do
        expect(subject.build).to include subject.send("link_#{rel}".to_sym)
      end

      unless rel == :original
        it "builds full link format without #{rel}" do
          subject.send("#{rel}=", nil)
          expect(subject.build).not_to include "rel=#{rel}"
        end
      end
    end
  end

  describe '#link_original' do
    it 'raises an error with no original' do
      expect { subject.link_original }.to raise_error(error)
    end

    it 'builds rel string' do
      subject.original = original

      expect(subject.link_original)
        .to eq "<#{original}>;rel=\"original\""
    end
  end

  describe '#link_timegate' do
    it 'raises an error with no original' do
      expect { subject.link_timegate }.to raise_error(error)
    end

    it 'builds rel string' do
      subject.timegate = timegate

      expect(subject.link_timegate)
        .to eq "<#{timegate}>;rel=\"timegate\""
    end
  end
end
