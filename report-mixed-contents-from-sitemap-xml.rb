require 'fileutils'
require 'logger'
require 'shellwords'

LOG = Logger.new(STDERR)

if ENV['DEBUG']
  LOG.level = Logger::DEBUG
else
  LOG.level = Logger::INFO
end

class Collector
  def initialize(sitemap_uri)
    @total = 0
    @ok = 0
    @failed = 0
    @sitemap_uri = sitemap_uri
  end

  def clone_repositories
    %w(sitemap-printer detect-mixed-content).each{|repository|
      system "git clone git@github.com:hitode909/#{repository}.git tmp/#{repository} >& /dev/null"
      FileUtils.chdir "tmp/#{repository}" do
        system 'git pull origin master >& /dev/null'
        system 'bundle install >& /dev/null'
      end
    }
  end

  def header
    puts "# mixed content report"
    puts "sitemap: #{@sitemap_uri}"
    puts
  end

  def collect_uris
    LOG.debug "collecting uris"
    collected = []
    FileUtils.chdir "tmp/sitemap-printer" do
      collected = `bundle exec -- bundle exec -- ruby sitemap-printer.rb #{ Shellwords.escape @sitemap_uri }`.split(/\n/)
    end

    collected
  end

  def crawl_uris uris
    uris.each{|uri|
      errors = collect_errors uri
      @total += 1
      if errors.empty?
        @ok += 1
        LOG.debug "OK"
        next
      else
        @failed += 1
        LOG.debug "failed"
      end

      puts "- #{uri}"
      puts errors.map{|error| " - #{ error }" }.join("\n")
    }
  end

  def summary
    puts "\n# summary"
    puts "total: #{ @total }, ok: #{ @ok }, failed: #{ @failed }"
  end

  def collect_errors uri
    LOG.debug "collect errors for #{uri}"
    errors = []
    FileUtils.chdir "tmp/detect-mixed-content" do
      errors = `phantomjs detect-mixed-content.js #{ Shellwords.escape uri }`.split(/\n/)
    end

    errors
  end
end

sitemap_uri = ARGV.first

unless sitemap_uri
  warn "usage: ruby report-mixed-contents-from-sitemap-xml.rb SITEMAP_XML_URI | tee tmp/a.md"
  exit 1
end

sitemap_uri = ARGV.first

c = Collector.new(sitemap_uri)
c.clone_repositories
uris = c.collect_uris
c.header
c.crawl_uris(uris)
c.summary
