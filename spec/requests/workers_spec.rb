require "rails_helper"

RSpec.describe "Workers", mutant_expression: "WorkersController*" do
  describe "GET /workers" do
    it "responds successfully with no workers" do
      get workers_url

      expect(response).to have_http_status(:success)
      expect(response.body).to include("datagrid-no-results")
    end

    it "links to the new worker form" do
      get workers_url

      expect(response.body).to include(%(href="#{new_worker_path}"))
    end

    it "lists each worker linked to its page, with qualifications" do
      worker = create(:worker, name: "Alice", qualifications: [ create(:qualification, name: "Fire Watch") ])

      get workers_url

      expect(response.body).to include(%(<a href="#{worker_path(worker)}">Alice</a>))
      expect(response.body).to include("Fire Watch")
    end

    it "paginates to 25 rows" do
      create_list(:worker, 30)

      get workers_url

      expect(response.body.scan(/<tr/).size).to eq(26)
    end

    it "serves a later page" do
      create_list(:worker, 30)

      get workers_url, params: { page: 2 }

      expect(response.body.scan(/<tr/).size).to eq(6)
    end

    it "orders by a requested column" do
      create(:worker, name: "Alpha")
      create(:worker, name: "Zulu")

      get workers_url, params: { workers_grid: { order: "name", descending: "true" } }

      expect(response.body.index("Zulu")).to be < response.body.index("Alpha")
    end
  end

  describe "GET /workers/new" do
    it "renders the name field" do
      get new_worker_url

      expect(response).to have_http_status(:success)
      expect(response.body).to include(%(name="worker[name]"))
      expect(response.body).not_to include("alert-danger")
    end
  end

  describe "POST /workers" do
    it "creates the worker and redirects to it" do
      expect { post workers_url, params: { worker: { name: "Alice" } } }
        .to change(Worker, :count).by(1)

      worker = Worker.last
      expect(worker.name).to eq("Alice")
      expect(response).to redirect_to(worker_path(worker))
      expect(flash[:notice]).to eq("Added Alice.")
    end

    it "ignores attributes other than name" do
      post workers_url, params: { worker: { name: "Alice", id: 4242 } }

      expect(Worker.last.id).not_to eq(4242)
    end

    it "re-renders the form with errors when the name is blank" do
      expect { post workers_url, params: { worker: { name: "" } } }
        .not_to change(Worker, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("alert-danger", "Name can&#39;t be blank")
    end

    it "rejects a request without worker params" do
      post workers_url, params: { name: "Alice" }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /workers/:id" do
    let(:fire_watch) { create(:qualification, name: "Fire Watch") }
    let!(:reactor) { create(:qualification, name: "Reactor Operator") }
    let!(:boiler) { create(:qualification, name: "Boiler Tender") }
    let!(:worker) { create(:worker, name: "Alice", qualifications: [ fire_watch ]) }

    it "titles the page with the worker's name" do
      get worker_url(worker)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Alice")
    end

    it "lists held qualifications with a remove button" do
      get worker_url(worker)

      wq = worker.worker_qualifications.first
      expect(response.body).to include("Fire Watch")
      expect(response.body).to include(%(action="#{worker_worker_qualification_path(worker, wq)}"))
      expect(response.body).to include(%(value="delete"))
    end

    it "offers only qualifications the worker lacks, alphabetically" do
      get worker_url(worker)

      options = response.body.scan(%r{<option value="(\d+)">([^<]+)</option>})
      expect(options).to eq([ [ boiler.id.to_s, "Boiler Tender" ], [ reactor.id.to_s, "Reactor Operator" ] ])
    end

    it "hides the add form when the worker holds every qualification" do
      worker.qualifications << [ reactor, boiler ]

      get worker_url(worker)

      expect(response.body).not_to include("Add qualification")
    end

    it "says so when the worker has no qualifications" do
      get worker_url(create(:worker))

      expect(response.body).to include("No qualifications.")
    end

    it "returns not found for an unknown worker" do
      get worker_url(id: 999_999)

      expect(response).to have_http_status(:not_found)
    end
  end
end
