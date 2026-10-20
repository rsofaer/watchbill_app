require "rails_helper"

RSpec.describe "Watchstations", mutant_expression: "WatchstationsController*" do
  let!(:watchset) { create(:watchset, name: "Indian Point") }
  let!(:qualification) { create(:qualification, name: "Firefighter") }

  describe "POST /watchsets/:watchset_id/watchstations" do
    it "adds a station requiring the chosen qualification to the watchset" do
      expect {
        post watchset_watchstations_url(watchset),
             params: { watchstation: { name: "Fire Watch", qualification_id: qualification.id } }
      }.to change(Watchstation, :count).by(1)

      station = Watchstation.last
      expect(station.name).to eq("Fire Watch")
      expect(station.watchset).to eq(watchset)
      expect(station.qualification).to eq(qualification)
    end

    it "returns to the edit page and confirms the addition" do
      post watchset_watchstations_url(watchset),
           params: { watchstation: { name: "Fire Watch", qualification_id: qualification.id } }

      expect(response).to redirect_to(edit_watchset_path(watchset))
      follow_redirect!
      expect(response.body).to include("Added Fire Watch.")
    end

    it "cannot be steered onto another watchset through the params" do
      other = create(:watchset)

      post watchset_watchstations_url(watchset),
           params: { watchstation: { name: "Fire Watch", qualification_id: qualification.id, watchset_id: other.id } }

      expect(Watchstation.last.watchset).to eq(watchset)
    end

    it "rerenders the edit page with errors when the name is blank" do
      expect {
        post watchset_watchstations_url(watchset),
             params: { watchstation: { name: "", qualification_id: qualification.id } }
      }.not_to change(Watchstation, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Name can&#39;t be blank", "Indian Point", "watchstation[name]")
    end

    it "rerenders the edit page with errors when no qualification is chosen" do
      expect {
        post watchset_watchstations_url(watchset), params: { watchstation: { name: "Fire Watch", qualification_id: "" } }
      }.not_to change(Watchstation, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Qualification must exist")
    end

    it "keeps the rejected station out of the station list" do
      post watchset_watchstations_url(watchset), params: { watchstation: { name: "Fire Watch", qualification_id: "" } }

      expect(response.body).to include("This watchset has no watchstations yet.")
    end

    it "rejects a qualification that does not exist" do
      expect {
        post watchset_watchstations_url(watchset),
             params: { watchstation: { name: "Fire Watch", qualification_id: 999_999 } }
      }.not_to change(Watchstation, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a request with no watchstation params" do
      post watchset_watchstations_url(watchset), params: { name: "Fire Watch" }

      expect(response).to have_http_status(:bad_request)
    end

    it "redirects to the list when the watchset does not exist" do
      expect {
        post watchset_watchstations_url(watchset_id: 999_999),
             params: { watchstation: { name: "Fire Watch", qualification_id: qualification.id } }
      }.not_to change(Watchstation, :count)

      expect(response).to redirect_to(watchsets_path)
      follow_redirect!
      expect(response.body).to include("Watchset not found.")
    end
  end

  describe "DELETE /watchsets/:watchset_id/watchstations/:id" do
    let!(:station) { create(:watchstation, watchset: watchset, name: "Fire Watch") }

    it "removes the station and confirms it on the edit page" do
      expect { delete watchset_watchstation_url(watchset, station) }.to change(Watchstation, :count).by(-1)

      expect(response).to redirect_to(edit_watchset_path(watchset))
      follow_redirect!
      expect(response.body).to include("Removed Fire Watch.")
    end

    it "leaves the qualification in place" do
      delete watchset_watchstation_url(watchset, station)

      expect(Qualification.exists?(station.qualification_id)).to be(true)
    end

    it "removes the station's assignments on any saved watchbill" do
      create(:watchbill_station_assignment, watchstation: station)

      expect { delete watchset_watchstation_url(watchset, station) }
        .to change(WatchbillStationAssignment, :count).by(-1)
    end

    it "will not remove a station that belongs to another watchset" do
      foreign = create(:watchstation)

      expect { delete watchset_watchstation_url(watchset, foreign) }.not_to change(Watchstation, :count)

      expect(response).to redirect_to(edit_watchset_path(watchset))
      follow_redirect!
      expect(response.body).to include("Watchstation not found.")
    end

    it "redirects to the list when the watchset does not exist" do
      expect { delete watchset_watchstation_url(watchset_id: 999_999, id: station.id) }
        .not_to change(Watchstation, :count)

      expect(response).to redirect_to(watchsets_path)
    end
  end
end
