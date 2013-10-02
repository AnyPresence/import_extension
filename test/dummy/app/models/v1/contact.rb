class V1::Contact
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessible :name, :email_address, :phone_number, :description, :priority, :as => :"System Admin"
  attr_accessible :name, :email_address, :phone_number, :description, :priority
  
  after_save :__sms_on_save_perform, :__email_on_save_perform
  
  #validates_presence_of :description
  
  field :name, type: String
  field :email_address, type: String
  field :phone_number, type: String
  field :description, type: String
  field :priority, type: Integer
  
  def __sms_on_save_perform
    p "Sending fake sms!"
  end
  
  def __email_on_save_perform
    p "Sending fake email!"
  end
  
end
