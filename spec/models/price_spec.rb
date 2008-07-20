require File.dirname(__FILE__) + '/../spec_helper'

describe Price do
  before do
    @happening = HappeningPage.create! :title => 't', :slug => 's', :breadcrumb => 'b', :starts_at => Time.now
  end

  it "should have a happening" do
    price = Price.new
    price.happening_page = @happening
    price.save!
    price = Price.find(price.id)
    price.happening_page.should == @happening
  end
end