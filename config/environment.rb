# Load the Rails application.
require File.expand_path('../application', __FILE__)
require 'anagrams'

# Initialize the Rails application.
Rails.application.initialize!

SocialAnagrams::Application.configure do
  config.words = '/home/david/git_projects/Lingua-Anagrams/mostly_inoffensive_words.txt'
  config.trial_threshold = 15
  config.trial_batch = 10
  config.batch = 20
  config.max = 40
  config.limit = 40
  config.trial_max = 30
  config.polling_interval = 10
end

module SocialAnagrams
  words = IO.readlines(SocialAnagrams::Application.config.words)
  ANA = Anagramizer.new([words], :limit => SocialAnagrams::Application.config.limit)
end

SocialAnagrams::Application.configure do
  config.name_variants = SocialAnagrams::ANA.anagrams('social anagrams').map { |a| a.shuffle }
end
