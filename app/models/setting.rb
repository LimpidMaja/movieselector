class Setting < ActiveRecord::Base
  require 'digest/sha1'

  validates :trakt_username, presence: true , allow_blank: false, if: "!private.nil?"
  validates :trakt_password, presence: true, allow_blank: false, if: "!private.nil?"

  before_save { |record| record.encrypt_password }

  protected

  # before filter
  def encrypt_password
    return if trakt_password.blank?
    self.trakt_password = Digest::SHA1.hexdigest(trakt_password) if trakt_password_changed?

    begin
      puts "PaSS:  " + trakt_username.to_s
      puts "PaSS:  " + trakt_password.to_s
      require 'trakt'
      trakt = Trakt.new
      trakt.apikey = Rails.application.secrets.trakt_API
      trakt.username = trakt_username
      trakt.password = trakt_password

      result = trakt.account.test    
    end
  rescue => e
    errors.add(:trakt_password, "Trakt authentication failed")
    logger.warn "Unable to authenticate trakt: #{e}"
    return false
  end
end
