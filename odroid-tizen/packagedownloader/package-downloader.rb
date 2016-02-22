require 'net/http'
require 'nokogiri'

# Script parses the HTML document containing the list of packages for a Tizen TV snapshot.
# All links to RPMs are parsed, and the corresponding files downloaded into a folder
# with the name of the value of the var RELEASE_TAG

def get_html(url)
  puts "loading URL: " + url
  uri = URI(url)
  response = Net::HTTP.start(uri.host, uri.port,
                             :use_ssl => uri.scheme == 'https') do |http|
    resp = http.get(uri.path)
    case resp
    when Net::HTTPSuccess then
      resp.body
    when Net::HTTPRedirection then
      warn "Redirected"
      resp.body
    else
      resp.value
    end
  end
end

def parse_html(html, package_folder_uri)
  html_doc = Nokogiri::HTML(html)
  nodes = html_doc.xpath("//a[@href]")
  raise "No <a .../> tags!" if nodes.empty?
  nodes.inject([]) do |uris, node|
    uris << package_folder_uri + node.attr('href').strip
  end.uniq
end


def downloader(url, paths, targetfolder)
  totalitems = paths.length
  itemsdownloaded = 0
  host_uri = URI(url)
  Dir.mkdir(targetfolder)
  Net::HTTP.start(host_uri.host, host_uri.port,
                    :use_ssl => host_uri.scheme == 'https') { |http|
    paths.each do |path|
      puts "Downloading: " + path
      begin
        resp = http.get(path)
        open(File.join(targetfolder, path.split('/')[-1]), "wb") do |file|
          file.write(resp.body)
          itemsdownloaded += 1
          puts("-- #{itemsdownloaded} of #{totalitems} --")
        end
      rescue                              
        test_response(resp)
      end
    end
  }
end

def test_response(resp)
  case resp
  when Net::HTTPServerError
    puts 'HTTPServerError'
  when Net::HTTPClientError
    puts 'HTTPClientError'
  when Net::HTTPRedirection
    puts 'HTTPRedirection'
  when Net::HTTPSuccess
    puts 'OK'
  else
    puts 'UNKNOWN'
  end
end

## process start here
RELEASE_TAG = "tizen-tv_20160212.2"
# var RELEASE_TAG = "tizen-tv_20160220.1"

SERVER = "https://download.tizen.org"
BASE_URI = "/snapshots/tizen/tv/"
package_folder_uri = BASE_URI + RELEASE_TAG + "/repos/arm-wayland/packages/armv7l/"

html = get_html(SERVER + package_folder_uri)
paths = parse_html(html, package_folder_uri)

# Remove all entries not ending in ".rpm"
paths.delete_if do |path|
  unless path.end_with? ".rpm"
    true # Make sure the if statement returns true, so it gets marked for deletion
  end
end

# download all imgs
downloader(SERVER + package_folder_uri, paths, RELEASE_TAG)

puts "All RPMs downloaded!"
