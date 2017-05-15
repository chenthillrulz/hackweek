class User < ActiveRecord::Base
  #devise :ichain_authenticatable, :ichain_registerable
  devise :ldap_authenticatable

  validates :name, presence: true
  validates :email, presence: true
  validates :login_name, presence: true
  validates_uniqueness_of :login_name
  #validates_uniqueness_of :email

  has_many :originated_projects, foreign_key: 'originator_id', class_name: Project
  has_many :updates, foreign_key: 'author_id', dependent: :destroy

  has_many :memberships
  has_many :comments
  has_many :likes
  has_many :enrollments

  has_many :projects, through: :memberships
  has_many :announcements, through: :enrollments
  has_many :favourites, through: :likes, source: :project

  has_many :user_interests
  has_many :keywords, through: :user_interests

  has_and_belongs_to_many :roles

  before_validation :get_ldap_attrs
  after_save ThinkingSphinx::RealTime.callback_for(:user)

  #include Gravtastic
  #has_gravatar
  has_attached_file :avatar, styles: { small: "100x100>"}, default_url: "/images/:style/missing.png"
  validates_attachment_file_name :avatar, matches: [/png\z/, /jpe?g\z/]

  def role?(role)
    return !!self.roles.find_by_name(role)
  end

  def to_param
    name
  end

  def get_ldap_attrs
    firstName = Devise::LDAP::Adapter.get_ldap_param(self.login_name,'givenName').first
    lastName = Devise::LDAP::Adapter.get_ldap_param(self.login_name,'sn').first
    self.name = firstName + ' ' + lastName;
    self.email = Devise::LDAP::Adapter.get_ldap_param(self.login_name,'mail').first

    photos = Devise::LDAP::Adapter.get_ldap_param(self.login_name,'thumbnailPhoto')

    if !photos.blank?
      ldap_photo = Devise::LDAP::Adapter.get_ldap_param(self.login_name,'thumbnailPhoto').first;

      if !ldap_photo.blank?
        data = StringIO.new(ldap_photo)
        data.class_eval do
          attr_accessor :content_type, :original_filename
        end

        data.content_type = "image/jpeg"
        data.original_filename = File.basename(self.login_name + ".jpg")
        self.avatar = data
      end
    end

  end

  def add_keyword! name
    name.downcase!
    name.gsub!(/\s/, '')
    keyword = Keyword.find_by_name name
    if !keyword
      keyword = Keyword.create! name: name
    end
    if !self.keywords.include? keyword
      self.keywords << keyword
      save!
    end
  end

  def remove_keyword! name
    keyword = Keyword.find_by_name name
    if self.keywords.include? keyword
      self.keywords.delete(keyword)
      save!
    end
  end

  def recommended_projects(episode = nil)
    if self.keywords.empty?
      return []
    end

    recommended = []
    self.keywords.each do |word|
      if episode
        projects = word.projects.select { |p| p.episodes.include?(episode)  }
      else
        projects = word.projects
      end
      projects.each do |p|
        next unless p.active?
        if episode
          recommended << p if p.episodes.include?(episode)
        else
          recommended << p
        end
      end
    end
    recommended.uniq
  end

  def self.for_ichain_username(username, attributes)
    user = find_by(name: username)
    if user
      user.update_attributes(email: attributes[:email]) if user.email != attributes[:email]
    else
      user = create(name: username, email: attributes[:email])
    end
    user
  end

  # hack for remember_token
  def authenticatable_token
    Digest::SHA1.hexdigest(email)[0,29]
  end
end
