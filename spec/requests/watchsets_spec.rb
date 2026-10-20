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

      it "links to the new watchset form" do
        get watchsets_url

        expect(response.body).to include(%(href="#{new_watchset_path}"))
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

      it "links each row to the page for editing its watchstations" do
        watchset = create(:watchset, name: "Indian Point")

        get watchsets_url

        expect(response.body).to include(%(href="#{edit_watchset_path(watchset)}"))
      end

      # The watchset page fails to render for a watchset nobody can staff (see
      # GET /watchsets/:id below), so the list links to the edit page instead.
      it "does not link a row to the watchset page" do
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

      it "links to the page for adding watchstations" do
        get watchset_url(watchset)

        expect(response.body).to include(%(href="#{edit_watchset_path(watchset)}"))
      end

      it "renders datagrid's no-results row instead of station rows" do
        get watchset_url(watchset)

        expect(response.body).to include("datagrid-no-results")
        expect(response.body.scan(/<tr/).size).to eq(2) # the header and the no-results row
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

  describe "GET /watchsets/new" do
    it "renders a form for naming the watchset" do
      get new_watchset_url

      expect(response).to have_http_status(:success)
      expect(response.body).to include("New Watchset", "watchset[name]", %(action="#{watchsets_path}"))
    end
  end

  describe "POST /watchsets" do
    it "creates the watchset and sends you on to add its watchstations" do
      expect { post watchsets_url, params: { watchset: { name: "Drydock" } } }
        .to change(Watchset, :count).by(1)

      watchset = Watchset.last
      expect(watchset.name).to eq("Drydock")
      expect(response).to redirect_to(edit_watchset_path(watchset))
      follow_redirect!
      expect(response.body).to include("Watchset created.")
    end

    it "rerenders the form with errors when the name is blank" do
      expect { post watchsets_url, params: { watchset: { name: "" } } }
        .not_to change(Watchset, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Name can&#39;t be blank", "watchset[name]")
    end

    it "ignores attributes other than the name" do
      post watchsets_url, params: { watchset: { name: "Drydock", created_at: "2001-01-01" } }

      expect(Watchset.last.created_at.year).not_to eq(2001)
    end

    it "rejects a request with no watchset params" do
      post watchsets_url, params: { name: "Drydock" }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /watchsets/:id/edit" do
    let!(:watchset) { create(:watchset, name: "Indian Point") }

    it "titles the page with the watchset name" do
      get edit_watchset_url(watchset)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Indian Point")
    end

    it "says so when the watchset has no watchstations" do
      get edit_watchset_url(watchset)

      expect(response.body).to include("This watchset has no watchstations yet.")
    end

    it "lists this watchset's stations by name with their qualifications and a remove button" do
      station = create(:watchstation, watchset: watchset, name: "Fire Watch",
                                      qualification: create(:qualification, name: "Firefighter"))
      create(:watchstation, name: "Elsewhere")

      get edit_watchset_url(watchset)

      expect(response.body).to include("Fire Watch", "Firefighter",
                                       %(action="#{watchset_watchstation_path(watchset, station)}"))
      expect(response.body).not_to include("Elsewhere", "This watchset has no watchstations yet.")
    end

    it "orders the stations by name" do
      create(:watchstation, watchset: watchset, name: "Zulu Watch")
      create(:watchstation, watchset: watchset, name: "Alpha Watch")

      get edit_watchset_url(watchset)

      expect(response.body.index("Alpha Watch")).to be < response.body.index("Zulu Watch")
    end

    it "offers every qualification, by name, for a new station" do
      create(:qualification, name: "Reactor Operator")
      create(:qualification, name: "Electrician")

      get edit_watchset_url(watchset)

      expect(response.body).to include("watchstation[name]", "watchstation[qualification_id]",
                                       %(action="#{watchset_watchstations_path(watchset)}"))
      expect(response.body.index("Electrician")).to be < response.body.index("Reactor Operator")
    end

    it "explains that a station cannot be added before any qualification exists" do
      get edit_watchset_url(watchset)

      expect(response.body).to include("There are no qualifications to require yet.")
      expect(response.body).not_to include("watchstation[name]")
    end

    it "redirects to the list when the id matches no watchset" do
      get edit_watchset_url(id: 999_999)

      expect(response).to redirect_to(watchsets_path)
      follow_redirect!
      expect(response.body).to include("Watchset not found.")
    end
  end
end
