class User < ApplicationRecord
  #TODO: Temp, move this when separate model for prog languages is created
  LEVELS = %w(expert proficient competent advanced_beginner novice).freeze
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  has_many :pair_requests, dependent: :destroy # TODO: Reconsider dependent option
  has_many :offers, foreign_key: :offerer_id, dependent: nil # TODO: Reconsider dependent option
  has_many :participations, foreign_key: :participant_id, dependent: nil # TODO: Reconsider dependent option
  has_many :sessions, through: :participations, source: :participable, source_type: Session.name

  validates :language, inclusion: { in: I18nData.languages.keys }, allow_nil: true
  validates :country, inclusion: { in: I18nData.countries.keys }, allow_nil: true
  validates :level, inclusion: { in: LEVELS }, allow_nil: true
end
