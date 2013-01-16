class V1::Outage
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessible :name, :description, :as => :"System Admin"
  attr_accessible :name, :description
  
  after_save :__sms_on_save_perform, :__email_on_save_perform
  
  field :name, type: String
  field :description, type: String
  
  def __sms_on_save_perform
    p "Sending fake sms!"
  end
  
  def __email_on_save_perform
    p "Sending fake email!"
  end
  
end
