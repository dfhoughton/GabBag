require 'notification'

class Anagram < ActiveRecord::Base
  belongs_to :phrase
  belongs_to :child, :class_name => 'Phrase'
  has_many :users, through: :favorites

  # a create-or-find method; returns nil if it could not be created
  def self.fetch(source, child)
    source = Phrase.fetch source
    return nil if source.nil?
    anagram = Phrase.fetch child
    return nil if anagram.nil?
    anagram = where(phrase_id: source.id, child_id: anagram.id).first_or_create
    return anagram
  end

  def notify(sender, recipient)
    Notification.create user: recipient, body: notification(sender)
  end

  def notify_all(sender, recipients)
    message = notification sender
    recipients.each { |r| Notification.create user: r, body: message }
  end

  private

  def notification(sender)
    message = {
        type: :share,
        from: sender.email,
        anagram: {
            id: id,
            source: phrase.text,
            anagram: child.text,
            favored: favored
        }
    }
    return message.to_json
  end
end
