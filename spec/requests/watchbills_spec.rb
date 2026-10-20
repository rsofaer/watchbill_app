require "rails_helper"

RSpec.describe "Watchbills", mutant_expression: "WatchbillsController*" do
  let(:watchset) { create(:watchset, name: "Indian Point") }
  let(:rover) { create(:watchstation, name: "Rover", watchset: watchset) }

  def staffed_params(station)
    attributes = WatchbillStationAssignment.shifts.keys.each_with_index.to_h do |shift, i|
      worker = create(:worker, name: "#{shift} Worker", qualifications: [ station.qualification ])
      [ i.to_s, { watchstation_id: station.id, shift: shift, worker_id: worker.id } ]
    end
    { watchbill: { watchbill_station_assignments_attributes: attributes } }
  end

  def staffed_bill(station)
    create(:watchbill, watchset: station.watchset).tap do |bill|
      staffed_params(station)[:watchbill][:watchbill_station_assignments_attributes].each_value do |a|
        bill.watchbill_station_assignments.create!(a)
      end
    end
  end

  describe "POST /watchsets/:watchset_id/watchbills" do
    it "saves to the watchset in the url, not whichever was made first" do
      create(:watchset, name: "Decoy")

      post watchset_watchbills_url(watchset), params: staffed_params(rover)

      expect(Watchbill.last.watchset).to eq(watchset)
    end

    it "saves the watchbill and its assignments" do
      expect { post watchset_watchbills_url(watchset), params: staffed_params(rover) }
        .to change(Watchbill, :count).by(1)
        .and change(WatchbillStationAssignment, :count).by(3)

      bill = Watchbill.last
      expect(bill.watchset).to eq(watchset)
      expect(bill.watchbill_station_assignments.map { |a| [ a.watchstation.name, a.shift, a.worker.name ] })
        .to contain_exactly([ "Rover", "Days", "Days Worker" ], [ "Rover", "Swings", "Swings Worker" ],
                            [ "Rover", "Mids", "Mids Worker" ])
    end

    it "redirects to the saved watchbill and says so" do
      post watchset_watchbills_url(watchset), params: staffed_params(rover)

      expect(response).to redirect_to(watchbill_path(Watchbill.last))
      follow_redirect!
      expect(response.body).to include("Watchbill saved.")
    end

    it "ignores attributes the form does not send" do
      params = staffed_params(rover)
      params[:watchbill][:watchset_id] = create(:watchset).id
      params[:watchbill][:watchbill_station_assignments_attributes]["0"][:watchbill_id] = 999

      post watchset_watchbills_url(watchset), params: params

      expect(Watchbill.last.watchset).to eq(watchset)
      expect(WatchbillStationAssignment.pluck(:watchbill_id).uniq).to eq([ Watchbill.last.id ])
    end

    it "saves an empty watchbill when no assignments are sent" do
      expect { post watchset_watchbills_url(watchset) }.to change(Watchbill, :count).by(1)

      expect(Watchbill.last.watchbill_station_assignments).to be_empty
    end

    context "when an assignment cannot be saved" do
      let(:params) do
        staffed_params(rover).tap do |p|
          p[:watchbill][:watchbill_station_assignments_attributes]["1"][:shift] = "Graveyard"
        end
      end

      it "saves nothing" do
        expect { post watchset_watchbills_url(watchset), params: params }
          .not_to change { [ Watchbill.count, WatchbillStationAssignment.count ] }
      end

      it "sends the user back to the watchset with the reason" do
        allow_any_instance_of(Watchset).to receive(:generate_watchbill) { |ws| Watchbill.new(watchset: ws) }

        post watchset_watchbills_url(watchset), params: params

        expect(response).to redirect_to(watchset_path(watchset))
        follow_redirect!
        expect(response.body).to include("Watchbill could not be saved: Watchbill station assignments shift is not included in the list")
      end
    end

    it "404s for a watchset that does not exist" do
      post watchset_watchbills_url(watchset_id: 999_999)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /watchbills/:id" do
    it "shows the watchbill in the url, not whichever was saved first" do
      create(:watchbill, watchset: create(:watchset, name: "Decoy"))
      bill = staffed_bill(rover)

      get watchbill_url(bill)

      expect(response.body).to include("Watchbill ##{bill.id}", "Indian Point")
      expect(response.body).not_to include("Decoy")
    end

    it "lays out the saved assignments one row per station" do
      bill = staffed_bill(rover)

      get watchbill_url(bill)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Days Worker", "Swings Worker", "Mids Worker")
      expect(response.body.scan(/<tr/).size).to eq(2) # the header and Rover
    end

    it "paginates its stations" do
      bill = staffed_bill(rover)
      create_list(:watchstation, 30, watchset: watchset)

      get watchbill_url(bill), params: { page: 2 }

      expect(response.body.scan(/<tr/).size).to eq(7) # the header and the last 6 of 31 stations
    end

    it "names the watchset and links back to it and to its other saved watchbills" do
      bill = staffed_bill(rover)

      get watchbill_url(bill)

      expect(response.body).to include("Indian Point", "Watchbill ##{bill.id}")
      expect(response.body).to include(%(href="#{watchset_path(watchset)}"))
      expect(response.body).to include(%(href="#{watchset_watchbills_path(watchset)}"))
    end

    it "only lists stations from the watchbill's own watchset" do
      bill = staffed_bill(rover)
      create(:watchstation, name: "Somebody Else's Station")

      get watchbill_url(bill)

      expect(response.body).not_to include("Somebody Else&#39;s Station")
    end

    it "says a properly staffed watchbill is valid" do
      get watchbill_url(staffed_bill(rover))

      expect(response.body).to include("This watchbill is valid.")
      expect(response.body).not_to include("not valid")
      expect(response.body).not_to include("watchbill-problems")
    end

    it "says a watchbill with staffing problems is not valid, and lists them" do
      bill = staffed_bill(rover)
      WorkerQualification.find_by!(worker: Worker.find_by!(name: "Mids Worker")).destroy

      get watchbill_url(bill)

      expect(response.body).to include("This watchbill is not valid.")
      expect(response.body).to include("<li>Mids Worker is not qualified for Rover (Mids)</li>")
      expect(response.body).not_to include("This watchbill is valid.")
    end

    it "404s for a watchbill that does not exist" do
      get watchbill_url(id: 999_999)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /watchsets/:watchset_id/watchbills" do
    it "lists the watchset's saved watchbills with whether each is valid" do
      good = staffed_bill(rover)
      bad = create(:watchbill, watchset: watchset)

      get watchset_watchbills_url(watchset)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Saved watchbills for", "Indian Point")
      expect(response.body).to include(%(href="#{watchbill_path(good)}"), %(href="#{watchbill_path(bad)}"))
      expect(response.body.scan(/<td[^>]*>(Yes|No)<\/td>/).flatten).to contain_exactly("Yes", "No")
    end

    it "leaves out other watchsets' watchbills" do
      other = create(:watchbill)

      get watchset_watchbills_url(watchset)

      expect(response.body).not_to include(%(href="#{watchbill_path(other)}"))
      expect(response.body).to include("datagrid-no-results")
    end

    it "paginates to 25 rows" do
      create_list(:watchbill, 30, watchset: watchset)

      get watchset_watchbills_url(watchset)
      expect(response.body.scan(/<tr/).size).to eq(26)

      get watchset_watchbills_url(watchset), params: { page: 2 }
      expect(response.body.scan(/<tr/).size).to eq(6)
    end

    it "orders by a requested column" do
      older = create(:watchbill, watchset: watchset, created_at: 2.days.ago)
      newer = create(:watchbill, watchset: watchset, created_at: 1.day.ago)

      get watchset_watchbills_url(watchset), params: { watchbills_grid: { order: "created_at", descending: "false" } }

      expect(response.body.index(watchbill_path(older))).to be < response.body.index(watchbill_path(newer))
    end

    it "404s for a watchset that does not exist" do
      get watchset_watchbills_url(watchset_id: 999_999)

      expect(response).to have_http_status(:not_found)
    end
  end
end
