class User < ActiveRecord::Base

  attr_accessor :remember_token, :activation_token
  before_save   :downcase_email
  before_create :create_activation_digest
  
  # NAME
  validates :name,  presence: true, length: { maximum: 50 }

  # EMAIL
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }

  # PASSWORD
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # HASH STUFF FOR TESTING
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # returns a random token
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # def authenticated?(attribute)
  #   digest = send("#{attribute}_digest")
  #   return false if digest.nil?
  #   BCrypt::Password.new(digest).is_password?(attribute_token)
  # end

  # Forgets a user.
  def forget
    update_attribute(:remember_digest, nil)
  end

  # activate account
  def activate
    update_attribute(:activated,    true)
    update_attribute(:activated_at, Time.zone.now)
  end

  # sends activation email
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  private

    #converts email to lowercase
    def downcase_email
      self.email = email.downcase
    end

    #creates and assigned the activation token/digest
    def create_activation_digest
      self.activation_token  = User.new_token
      self.activation_digest = User.digest(activation_token)
    end
end
