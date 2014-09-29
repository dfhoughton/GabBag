class Phrase < ActiveRecord::Base
  # a find-or-create method; returns nil if the parameter is nil or contains no word after trimming
  def self.fetch(string)
    return nil if string.nil?
    string = string.gsub /\A\s+|\s+\z/, ''
    string = string.gsub /\s+/, ' '
    return nil unless string.length > 0
    p = find_by(text: string) || create(text: string)
    return p
  end
end
