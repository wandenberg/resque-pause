source "http://rubygems.org"

# Specify your gem's dependencies in resque-pause.gemspec
gemspec

gem "rake"

group :test, :development do
  platforms :mri_18 do
    gem "ruby-debug"
  end

  platforms :mri_19 do
    gem "ruby-debug19", :require => 'ruby-debug' if RUBY_VERSION < "1.9.3"
  end
end
