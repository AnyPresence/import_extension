class V1::Outage
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessible :name, :description
  
  field :name, type: String
  field :description, type: String
end
