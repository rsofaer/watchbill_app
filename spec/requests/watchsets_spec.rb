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

      it "links each row to the watchset it names" do
        watchset = create(:watchset, name: "Indian Point")

        get watchsets_url

        expect(response.body).to include(%(<a href="#{watchset_path(watchset)}">Indian Point</a>))
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

      it "narrows the list by name" do
        create(:watchset, name: "Indian Point")
        create(:watchset, name: "Drydock")

        get watchsets_url, params: { watchsets_grid: { name: "Indian Point" } }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Indian Point")
        expect(response.body).not_to include("Drydock")
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
    end

    context "when the watchset has stations but nobody is qualified" do
      let!(:watchset) { create(:watchset, name: "Unstaffed") }

      before { create(:watchstation, name: "Rover", watchset: watchset) }

      it "renders the stations with every shift blank" do
        get watchset_url(watchset)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Rover")
        expect(response.body).not_to include("datagrid-no-results")
      end

      it "says that no valid watchbill exists" do
        get watchset_url(watchset)

        expect(response.body).to include("No valid watchbill exists")
      end
    end

    context "when the watchset can be fully staffed" do
      it "names a qualified worker in every shift" do
        watchset = create(:watchset, name: "Staffed")
        qualification = create(:qualification)
        create(:watchstation, name: "Rover", watchset: watchset, qualification: qualification)
        names = %w[Ann Bo Cy]
        names.each { |name| create(:worker, name: name, qualifications: [ qualification ]) }

        get watchset_url(watchset)

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("No valid watchbill exists")
        names.each { |name| expect(response.body).to include(name) }
      end
    end

    context "when the watchset has many stations" do
      let!(:watchset) { create(:watchset, name: "Big") }

      before do
        30.times { |i| create(:watchstation, name: format("Station %02d", i), watchset: watchset) }
        create(:watchstation, name: "Somebody Else's Station", watchset: create(:watchset))
      end

      it "lists only this watchset's stations, 25 to a page" do
        get watchset_url(watchset)

        expect(response.body).not_to include("Somebody Else's Station")
        expect(response.body.scan(/<tr/).size).to eq(26) # 25 rows plus the header
      end

      it "serves the remaining stations on the next page" do
        get watchset_url(watchset), params: { page: 2 }

        expect(response.body.scan(/<tr/).size).to eq(6) # 5 rows plus the header
        expect(response.body).not_to include("Somebody Else's Station")
      end

      it "orders the stations as requested" do
        get watchset_url(watchset), params: { watchset_grid: { order: "name", descending: "true" } }

        expect(response.body).to include("Station 29")
        expect(response.body).not_to include("Station 00")
      end
    end

    context "when the id matches no watchset" do
      it "redirects to the list" do
        get watchset_url(id: 999_999)

        expect(response).to redirect_to(watchsets_path)
      end

      it "shows why on the list" do
        get watchset_url(id: 999_999)
        follow_redirect!

        expect(response.body).to include(%(<div class="alert alert-danger" role="alert">Watchset not found.</div>))
      end
    end
  end
end
