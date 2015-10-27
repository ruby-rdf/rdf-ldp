require 'bundler/setup'
require 'lamprey'
require 'rdf/blazegraph'
require 'benchmark'

task :benchmark do
  include Benchmark

  begin 
    REPOSITORY = RDF::Blazegraph::Repository.new('http://localhost:9999/bigdata/sparql')
    REPOSITORY.count # touch the repository, if it's not up, use in-memory
  rescue
    REPOSITORY = RDF::Repository.new
  end

  REPOSITORY.clear!
  TURTLE = File.open('etc/doap.ttl').read

  def benchmark(container_class)
    count = RDF::Reader.for(:ttl).new(TURTLE).statements.count
    puts "#{REPOSITORY.class}"
    puts "\n#{container_class.to_uri}"
    puts "\t10 Containers; 100 LDP-RS & LDP-NR per Container;\n\t#{count} statements per LDP-RS; GET/HEAD x 5\n\n"

    Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |bm|
      10.times do |i|
        bm.report('LDP-RS POST:') do
          container = container_class.new(RDF::URI("http://example.org/#{container_class}/rs/#{i}"), REPOSITORY)
          container.request(:put, 200, {}, {'CONTENT_TYPE' => 'application/n-triples', 'rack.input' => ''})
          
          100.times do
            container.request(:post, 200, {}, {'CONTENT_TYPE' => 'text/turtle', 'rack.input' => TURTLE})
          end
        end
      end
    end

    Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |bm|
      10.times do |i|
        bm.report('LDP-RS GET:') do
          container = container_class.new(RDF::URI("http://example.org/#{container_class}/rs/#{i}"), REPOSITORY)
          5.times do 
            container.graph.objects.each do |rs_uri|
              RDF::LDP::RDFSource.new(rs_uri, REPOSITORY).request(:get, 200, {}, {})
            end
          end
        end
      end
    end

    Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |bm|
      10.times do |i|
        bm.report('LDP-RS HEAD:') do
          container = container_class.new(RDF::URI("http://example.org/#{container_class}/rs/#{i}"), REPOSITORY)
          5.times do 
            container.graph.objects.each do |rs_uri|
              RDF::LDP::RDFSource.new(rs_uri, REPOSITORY).request(:head, 200, {}, {})
            end
          end
        end
      end
    end

    Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |bm|
      10.times do |i|
        bm.report('LDP-RS PUT:') do
          container = container_class.new(RDF::URI("http://example.org/#{container_class}/rs/#{i}"), REPOSITORY)

          container.graph.objects.each do |rs_uri|
            RDF::LDP::RDFSource.new(rs_uri, REPOSITORY).request(:put, 200, {}, {'CONTENT_TYPE' => 'text/turtle', 'rack.input' => ''})
          end
        end
      end
    end

    Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |bm|
      10.times do |i|
        bm.report('LDP-NR:') do
          container = container_class.new(RDF::URI("http://example.org/#{container_class}/nr/#{i}"), REPOSITORY)
          container.request(:put, 200, {}, {'CONTENT_TYPE' => 'application/n-triples', 'rack.input' => ''})
          
          100.times do
            container.request(:post, 200, {}, {'HTTP_LINK' => '<http://www.w3.org/ns/ldp#NonRDFSource>;rel=type', 'CONTENT_TYPE' => 'image/tiff', 'rack.input' => StringIO.new('')})
          end
        end
      end
    end
    REPOSITORY.clear!
  end

  benchmark(RDF::LDP::Container)
  benchmark(RDF::LDP::DirectContainer)
  benchmark(RDF::LDP::IndirectContainer)

  REPOSITORY.clear!
end

task :bm => :benchmark
