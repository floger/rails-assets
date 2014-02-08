class Component < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true

  has_many :versions, dependent: :destroy, autosave: false, validate: false

  def full_name
    GEM_PREFIX + name
  end

  def self.get(name, version)
    if component = where(name: name).first
      if version.blank?
        [component]
      elsif version = component.versions.string(version).first
        [component, version]
      else
        [component, component.versions.new(string: version)]
      end
    else
      component = new(name: name)

      if version.blank?
        [component]
      else
        [component, component.versions.new(string: version)]
      end
    end
  end

  def self.needs_build?(name, version = nil)
    component = Component.includes(:versions).references(:versions).
      where(name: name).first

    if version.nil?
      component.blank? || component.versions.builded.count == 0
    else
      version_model = component.versions.find_by(version: version)
      version_model.blank? || version_model.needs_build?
    end
  end

  def built?
    versions.builded.count > 0
  end
end
