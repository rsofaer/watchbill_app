require "rails_helper"

# `mutant_expression` binds these examples to the controller for mutation
# testing. Without it mutant derives the subject from the first word of the
# description -- "Watchsets" -- which matches no class, so every
# WatchsetsController mutation is reported alive against zero tests.
RSpec.describe "Watchsets", mutant_expression: "WatchsetsController*" do
  describe "GET /watchsets" do
    context "with no watchsets" do
      it "responds successfully" do
        get watchsets_url

        expect(response).to have_http_status(:success)
      end

      it "still renders the grid header and the filter form" do
        get watchsets_url

        expect(response.body).to include("Your Watchbills")
        expect(response.body).to include("Name")
        expect(response.body).to include("watchsets_grid[name]")
      end

      it "renders datagrid's no-results row instead of data rows" do
        get watchsets_url

        expect(response.body).to include("datagrid-no-results")
      end
    end

    context "with a handful of watchsets" do
      it "lists each one by name" do
        create(:watchset, name: "Indian Point Normal Operations")
        create(:watchset, name: "Drydock")

        get watchsets_url

        expect(response.body).to include("Indian Point Normal Operations", "Drydock")
      end

      it "formats the creation date as mm/dd/yyyy" do
        create(:watchset, name: "Dated", created_at: Time.zone.local(2026, 3, 7, 12, 0))

        get watchsets_url

        expect(response.body).to include("03/07/2026")
      end

      # The grid has a name column and a date column and nothing else, so
      # there is still no way to reach a watchset from the list.
      it "does not yet link a row to the watchset it names" do
        watchset = create(:watchset, name: "Indian Point")

        get watchsets_url

        expect(response.body).not_to include(%(href="#{watchset_path(watchset)}"))
      end
    end

    context "with more watchsets than fit on a page" do
      before { create_list(:watchset, 60) }

      it "responds successfully" do
        get watchsets_url

        expect(response).to have_http_status(:success)
      end

      it "paginates to 25 rows" do
        get watchsets_url

        expect(response.body.scan(/<tr/).size).to eq(26) # 25 rows plus the header
      end

      it "renders pagination controls" do
        get watchsets_url

        expect(response.body).to include("pagination")
      end

      it "serves a second page of different rows" do
        get watchsets_url
        first_page = response.body
        get watchsets_url, params: { page: 2 }

        expect(response).to have_http_status(:success)
        expect(response.body).not_to eq(first_page)
      end

      it "serves the last page" do
        get watchsets_url, params: { page: 3 }

        expect(response).to have_http_status(:success)
        expect(response.body.scan(/<tr/).size).to eq(11) # 10 rows plus the header
      end

      it "accepts a page past the end without blowing up" do
        get watchsets_url, params: { page: 99 }

        expect(response).to have_http_status(:success)
      end
    end

    describe "filtering" do
      it "narrows the list by created_at range" do
        create(:watchset, name: "Ancient", created_at: Time.zone.local(2020, 1, 1))
        create(:watchset, name: "Current", created_at: Time.zone.local(2026, 6, 1))

        get watchsets_url, params: {
          watchsets_grid: { created_at: [ "2026-01-01", "2026-12-31" ] }
        }

        expect(response.body).to include("Current")
        expect(response.body).not_to include("Ancient")
      end

      it "ignores a non-numeric name filter, because that filter is an integer filter" do
        create(:watchset, name: "Indian Point")

        get watchsets_url, params: { watchsets_grid: { name: "Indian Point" } }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Indian Point")
      end

      it "orders by a requested column without error" do
        create(:watchset, name: "Zulu")
        create(:watchset, name: "Alpha")

        get watchsets_url, params: { watchsets_grid: { order: "name", descending: "true" } }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Zulu", "Alpha")
      end
    end
  end

  describe "GET /" do
    it "routes the root path to the watchset index" do
      get root_url

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Your Watchbills")
    end
  end

  describe "GET /watchsets/:id" do
    context "when the watchset has no watchstations" do
      let!(:watchset) { create(:watchset, name: "Empty") }

      it "responds successfully" do
        get watchset_url(watchset)

        expect(response).to have_http_status(:success)
      end

      it "titles the page with the watchset name" do
        get watchset_url(watchset)

        expect(response.body).to include("Empty")
      end

      it "renders the shift headers over an empty table" do
        get watchset_url(watchset)

        expect(response.body).to include("Watchstation", "Days", "Swings", "Mids")
      end

      it "renders datagrid's no-results row instead of station rows" do
        get watchset_url(watchset)

        expect(response.body).to include("datagrid-no-results")
        expect(response.body.scan(/<tr/).size).to eq(2) # the header and the no-results row
      end

      it "offers no save button, because there is no watchbill to save" do
        get watchset_url(watchset)

        expect(response.body).not_to include("save-watchbill", "Save this watchbill")
      end

      it "links to the watchset's saved watchbills with a count" do
        create_list(:watchbill, 2, watchset: watchset)
        create(:watchbill)

        get watchset_url(watchset)

        expect(response.body).to include(%(<a href="#{watchset_watchbills_path(watchset)}">Saved watchbills (2)</a>))
      end
    end

    # The solver can run only once per process (see watchset_solver_spec.rb),
    # so these stand a hand-built watchbill in for the one it would generate.
    context "when a watchbill has been generated" do
      let!(:watchset) { create(:watchset, name: "Staffed") }
      let(:rover) { create(:watchstation, name: "Rover", watchset: watchset) }
      let(:workers) { create_list(:worker, 3, qualifications: [ rover.qualification ]) }
      let(:generated) do
        Watchbill.new(watchset: watchset).tap do |bill|
          WatchbillStationAssignment.shifts.each_key.zip(workers) do |shift, worker|
            bill.watchbill_station_assignments.build(watchstation: rover, shift: shift, worker: worker)
          end
        end
      end

      before do
        allow(Watchset).to receive(:find_by).with(id: watchset.id.to_s).and_return(watchset)
        allow(watchset).to receive(:generate_watchbill).and_return(generated)
      end

      it "offers a button that posts the watchbill to be saved" do
        get watchset_url(watchset)

        expect(response.body).to include(%(action="#{watchset_watchbills_path(watchset)}"))
        expect(response.body).to include(%(value="Save this watchbill"))
      end

      it "carries every assignment in the save form" do
        get watchset_url(watchset)

        WatchbillStationAssignment.shifts.each_key.with_index.zip(workers) do |(shift, i), worker|
          prefix = "watchbill[watchbill_station_assignments_attributes][#{i}]"
          expect(response.body).to include(%(value="#{rover.id}" name="#{prefix}[watchstation_id]"))
          expect(response.body).to include(%(value="#{shift}" name="#{prefix}[shift]"))
          expect(response.body).to include(%(value="#{worker.id}" name="#{prefix}[worker_id]"))
        end
      end

      it "saves the generated watchbill when that form is submitted" do
        get watchset_url(watchset)
        fields = response.body.scan(/value="([^"]*)" name="(watchbill\[[^"]+)"/).map(&:reverse)
        expect(fields.size).to eq(9)

        expect { post watchset_watchbills_url(watchset), params: URI.encode_www_form(fields) }
          .to change(Watchbill, :count).by(1)
        expect(Watchbill.last).to be_properly_staffed
      end
    end

    # The two contexts below pin bugs that are live today. They assert the
    # failure rather than the behaviour the page is reaching for, so that
    # fixing either one turns a spec red and asks to be updated.
    context "when the watchset has stations but nobody is qualified" do
      it "fails to render, because #generate_watchbill returns nil and the grid dereferences it" do
        watchset = create(:watchset, name: "Unstaffed")
        create_list(:watchstation, 3, watchset: watchset)

        expect { get watchset_url(watchset) }
          .to raise_error(ActionView::Template::Error, /watchbill_station_assignments/)
      end
    end

    context "when the id matches no watchset" do
      it "fails after the redirect, because #show carries on past it" do
        expect { get watchset_url(id: 999_999) }
          .to raise_error(NoMethodError, /generate_watchbill/)
      end
    end
  end
end
