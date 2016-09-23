# report-mixed-contents-from-sitemap-xml.rb

This script crawls sitemap.xml and reports insecure mixed contents.
This is useful when you are managing HTTPS web site.

## Setup

```
brew install phantomjs
```

## Run

```
ruby report-mixed-contents-from-sitemap-xml.rb SITEMAP_XML_URI | tee tmp/a.md
```
