#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "yaml"
require "json"

ROOT = File.expand_path("..", __dir__)
SITE = File.join(ROOT, "docs", "site")
BOOK = File.join(ROOT, "docs", "book")
CHAPTERS_DIR = File.join(BOOK, "chapters")
ASSETS_DIR = File.join(BOOK, "assets")
SITE_CHAPTERS = File.join(SITE, "_chapters")
SITE_ASSETS = File.join(SITE, "assets", "book")
SITE_JS = File.join(SITE, "assets", "js")

FileUtils.mkdir_p(SITE_CHAPTERS)
FileUtils.mkdir_p(SITE_ASSETS)
FileUtils.mkdir_p(SITE_JS)

# Only process if external book source exists
summary_path = File.join(BOOK, "SUMMARY.md")
chapters = []

if File.exist?(summary_path)
  summary = File.read(summary_path)
  link_rx = /\[(.+?)\]\((chapters\/[^\)]+\.md)\)/
  summary.scan(link_rx) do |title, rel|
    file = rel.sub("chapters/", "")
    slug = File.basename(file, ".md")
    chapters << { "title" => title.strip, "file" => file, "slug" => slug }
  end
end

chapter_index = {}
chapters.each_with_index { |c, i| chapter_index[c["file"]] = i + 1 }

link_map = chapters.each_with_object({}) do |c, h|
  h[c["file"]] = "/book/#{c["slug"]}/"
end


def rewrite_links(text, link_map, assets_prefix)
  out = text.dup
  out.gsub!(/\((?:\.\/)?assets\//, "(#{assets_prefix}")
  out.gsub!(/\((?:\.\/)?chapters\/([^\)]+\.md)\)/) do
    file = Regexp.last_match(1)
    "(#{link_map[file] || "#"})"
  end
  out
end

def strip_md(text)
  out = text.dup
  out.gsub!(/^---\n.*?^---\n/m, "")
  out.gsub!(/```.*?```/m, " ")
  out.gsub!(/`[^`]+`/, " ")
  out.gsub!(/\[(.*?)\]\([^\)]+\)/, "\\1")
  out.gsub!(/#+\s+/, " ")
  out.gsub!(/\s+/, " ")
  out.strip
end

def read_version(root)
  vfile = File.join(root, "version")
  return "dev" unless File.exist?(vfile)
  raw = File.read(vfile)
  m = /\"([^\"]+)\"/.match(raw)
  m ? m[1] : "dev"
end

def read_git_tags(root)
  git = File.join(root, ".git")
  return [] unless Dir.exist?(git)
  out = `git -C #{root} tag --list`
  return [] if out.nil? || out.empty?
  out.split("\n").map(&:strip).reject(&:empty?)
rescue
  []
end

chapters.each_with_index do |ch, idx|
  src = File.join(CHAPTERS_DIR, ch["file"])
  next unless File.exist?(src)
  raw = File.read(src)
  title = raw[/^#\s+(.+)$/, 1] || ch["title"]
  body = rewrite_links(raw, link_map, "/assets/book/")

  front = {
    "title" => title,
    "order" => idx + 1,
    "source" => "docs/book/chapters/#{ch["file"]}",
  }

  dest = File.join(SITE_CHAPTERS, "#{ch["slug"]}.md")
  yaml = front.to_yaml.lines.drop(1).join
  File.write(dest, "---\n" + yaml + "---\n\n" + body)
end

# Copy book assets
if Dir.exist?(ASSETS_DIR)
  FileUtils.rm_rf(SITE_ASSETS)
  FileUtils.mkdir_p(SITE_ASSETS)
  FileUtils.cp_r(Dir.glob(File.join(ASSETS_DIR, "*")), SITE_ASSETS)
end

# Sync guide pages
pages = {
  "cli" => File.join(ROOT, "docs", "cli.md"),
  "errors" => File.join(ROOT, "docs", "errors.md"),
  "stdlib" => File.join(ROOT, "docs", "stdlib.md"),
  "grammar" => File.join(ROOT, "docs", "grammar", "README.md"),
}

FileUtils.mkdir_p(File.join(SITE, "pages"))

pages.each do |slug, path|
  next unless File.exist?(path)
  raw = File.read(path)
  title = raw[/^#\s+(.+)$/, 1] || slug.capitalize
  body = rewrite_links(raw, link_map, "/assets/book/")
  front = {
    "title" => title,
    "permalink" => "/pages/#{slug}/",
  }
  dest = File.join(SITE, "pages", "#{slug}.md")
  yaml = front.to_yaml.lines.drop(1).join
  File.write(dest, "---\n" + yaml + "---\n\n" + body)
end

# Navigation data
nav = {
  "book" => chapters.map { |c| { "title" => c["title"], "url" => "/book/#{c["slug"]}/" } },
  "guides" => [
    { "title" => "CLI", "url" => "/pages/cli/" },
    { "title" => "Stdlib", "url" => "/pages/stdlib/" },
    { "title" => "Grammar", "url" => "/pages/grammar/" },
    { "title" => "Errors", "url" => "/pages/errors/" },
  ],
}

nav_data_dir = File.join(SITE, "_data")
FileUtils.mkdir_p(nav_data_dir)
nav_path = File.join(nav_data_dir, "nav.yml")
File.write(nav_path, nav.to_yaml)

# Versions data
version = read_version(ROOT)
tags = read_git_tags(ROOT)
items = [{ "label" => version, "url" => "/" }]
tags.each do |t|
  items << { "label" => t, "url" => "/versions/#{t}/" }
end
versions = {
  "current" => version,
  "items" => items,
}
versions_path = File.join(SITE, "_data", "versions.yml")
File.write(versions_path, versions.to_yaml)

# Versioned book/pages (from git tags)
def read_file_at_tag(root, tag, path)
  out = `git -C #{root} show #{tag}:#{path} 2> /dev/null`
  return nil if out.nil? || out.empty?
  out
rescue
  nil
end

def list_files_at_tag(root, tag, path)
  out = `git -C #{root} ls-tree -r --name-only #{tag} #{path} 2> /dev/null`
  return [] if out.nil? || out.empty?
  out.split("\n").map(&:strip).reject(&:empty?)
rescue
  []
end

version_nav = {}

tags.each do |tag|
  summary_tag = read_file_at_tag(ROOT, tag, "docs/book/SUMMARY.md")
  next unless summary_tag

  tag_chapters = []
  summary_tag.scan(link_rx) do |title, rel|
    file = rel.sub("chapters/", "")
    slug = File.basename(file, ".md")
    tag_chapters << { "title" => title.strip, "file" => file, "slug" => slug }
  end

  vroot = File.join(SITE, "versions", tag)
  vbook = File.join(vroot, "book")
  vpages = File.join(vroot, "pages")
  vassets = File.join(vroot, "assets", "book")
  FileUtils.mkdir_p(vbook)
  FileUtils.mkdir_p(vpages)
  FileUtils.mkdir_p(vassets)

  vlink_map = tag_chapters.each_with_object({}) do |c, h|
    h[c["file"]] = "/versions/#{tag}/book/#{c["slug"]}/"
  end

  # Chapters
  tag_chapters.each_with_index do |ch, idx|
    raw = read_file_at_tag(ROOT, tag, "docs/book/chapters/#{ch["file"]}")
    next unless raw
    title = raw[/^#\s+(.+)$/, 1] || ch["title"]
    body = rewrite_links(raw, vlink_map, "/versions/#{tag}/assets/book/")
    front = {
      "title" => title,
      "order" => idx + 1,
      "version" => tag,
      "permalink" => "/versions/#{tag}/book/#{ch["slug"]}/",
    }
    dest = File.join(vbook, "#{ch["slug"]}.md")
    yaml = front.to_yaml.lines.drop(1).join
    File.write(dest, "---\n" + yaml + "---\n\n" + body)
  end

  # Book index
  index_body = "# Vitte Book (#{tag})\n\n"
  tag_chapters.each do |c|
    index_body << "- [#{c["title"]}](/versions/#{tag}/book/#{c["slug"]}/)\n"
  end
  index_front = {
    "title" => "Vitte Book (#{tag})",
    "version" => tag,
    "permalink" => "/versions/#{tag}/book/",
  }
  yaml = index_front.to_yaml.lines.drop(1).join
  File.write(File.join(vbook, "index.md"), "---\n" + yaml + "---\n\n" + index_body)

  # Version landing page
  landing = {
    "title" => "Vitte #{tag}",
    "version" => tag,
    "permalink" => "/versions/#{tag}/",
  }
  landing_body = "# Vitte #{tag}\n\n- [Book](/versions/#{tag}/book/)\n- [CLI](/versions/#{tag}/pages/cli/)\n- [Stdlib](/versions/#{tag}/pages/stdlib/)\n- [Grammar](/versions/#{tag}/pages/grammar/)\n- [Errors](/versions/#{tag}/pages/errors/)\n"
  yaml = landing.to_yaml.lines.drop(1).join
  File.write(File.join(vroot, "index.md"), "---\n" + yaml + "---\n\n" + landing_body)

  # Versioned guides
  pages.each do |slug, _|
    raw = read_file_at_tag(ROOT, tag, "docs/#{slug}.md")
    if slug == "grammar"
      raw = read_file_at_tag(ROOT, tag, "docs/grammar/README.md")
    end
    next unless raw
    title = raw[/^#\s+(.+)$/, 1] || slug.capitalize
    body = rewrite_links(raw, vlink_map, "/versions/#{tag}/assets/book/")
    front = {
      "title" => title,
      "version" => tag,
      "permalink" => "/versions/#{tag}/pages/#{slug}/",
    }
    yaml = front.to_yaml.lines.drop(1).join
    File.write(File.join(vpages, "#{slug}.md"), "---\n" + yaml + "---\n\n" + body)
  end

  # Assets
  asset_files = list_files_at_tag(ROOT, tag, "docs/book/assets")
  asset_files.each do |asset_path|
    data = read_file_at_tag(ROOT, tag, asset_path)
    next unless data
    rel = asset_path.sub("docs/book/assets/", "")
    dest = File.join(vassets, rel)
    FileUtils.mkdir_p(File.dirname(dest))
    File.binwrite(dest, data)
  end

  version_nav[tag] = tag_chapters.map do |c|
    { "title" => c["title"], "url" => "/versions/#{tag}/book/#{c["slug"]}/", "order" => tag_chapters.index(c) + 1 }
  end
end

version_nav_path = File.join(SITE, "_data", "version_nav.yml")
File.write(version_nav_path, version_nav.to_yaml)

# Search index
search_entries = []
chapters.each do |ch|
  path = File.join(SITE_CHAPTERS, "#{ch["slug"]}.md")
  next unless File.exist?(path)
  raw = File.read(path)
  title = raw[/^title:\s*(.+)$/, 1] || ch["title"]
  text = strip_md(raw)
  search_entries << { "title" => title, "url" => "/book/#{ch["slug"]}/", "text" => text }
end

pages.each do |slug, _|
  path = File.join(SITE, "pages", "#{slug}.md")
  next unless File.exist?(path)
  raw = File.read(path)
  title = raw[/^title:\s*(.+)$/, 1] || slug.capitalize
  text = strip_md(raw)
  search_entries << { "title" => title, "url" => "/pages/#{slug}/", "text" => text }
end

tags.each do |tag|
  vbook = File.join(SITE, "versions", tag, "book")
  vpages = File.join(SITE, "versions", tag, "pages")
  if Dir.exist?(vbook)
    Dir.glob(File.join(vbook, "*.md")).each do |p|
      raw = File.read(p)
      title = raw[/^title:\s*(.+)$/, 1] || File.basename(p, ".md")
      url = raw[/^permalink:\s*(.+)$/, 1] || "/versions/#{tag}/book/"
      text = strip_md(raw)
      search_entries << { "title" => "#{title} (#{tag})", "url" => url, "text" => text }
    end
  end
  if Dir.exist?(vpages)
    Dir.glob(File.join(vpages, "*.md")).each do |p|
      raw = File.read(p)
      title = raw[/^title:\s*(.+)$/, 1] || File.basename(p, ".md")
      url = raw[/^permalink:\s*(.+)$/, 1] || "/versions/#{tag}/"
      text = strip_md(raw)
      search_entries << { "title" => "#{title} (#{tag})", "url" => url, "text" => text }
    end
  end
end

index_path = File.join(SITE_JS, "search-index.json")
File.write(index_path, JSON.pretty_generate(search_entries))
