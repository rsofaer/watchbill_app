require "rails_helper"

RSpec.describe "Watchsets" do
  describe "GET /watchsets" do
    it "responds successfully" do
      get watchsets_url
      expect(response).to have_http_status(:success)
    end
  end
end
