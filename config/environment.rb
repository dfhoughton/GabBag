# Load the Rails application.
require File.expand_path('../application', __FILE__)
require 'anagrams'

# Initialize the Rails application.
Rails.application.initialize!

SocialAnagrams::Application.configure do
  config.words = '/home/david/git_projects/Lingua-Anagrams/mostly_inoffensive_words.txt'
  config.trial_threshold = 12
  config.trial_batch = 20
  config.batch = 100
  config.max = 60
  config.threshold = 15
  config.limit = config.threshold
  config.trial_max = 20
  config.polling_interval = 60
  config.max_results = 10000
end

module SocialAnagrams
  words = IO.readlines(SocialAnagrams::Application.config.words)
  ANA = Anagramizer.new([words], :limit => SocialAnagrams::Application.config.limit)
end

SocialAnagrams::Application.configure do
  config.name_variants = SocialAnagrams::ANA.anagrams('social anagrams').map { |a| a.shuffle }
end
