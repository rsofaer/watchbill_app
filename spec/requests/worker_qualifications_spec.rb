require "rails_helper"

RSpec.describe "WorkerQualifications", mutant_expression: "WorkerQualificationsController*" do
  let(:worker) { create(:worker) }
  let(:qualification) { create(:qualification, name: "Fire Watch") }

  describe "POST /workers/:worker_id/worker_qualifications" do
    it "qualifies the worker and redirects back" do
      post worker_worker_qualifications_url(worker),
        params: { worker_qualification: { qualification_id: qualification.id } }

      expect(worker.reload.qualifications).to contain_exactly(qualification)
      expect(response).to redirect_to(worker_path(worker))
      expect(flash[:notice]).to eq("Added Fire Watch.")
    end

    it "adds the qualification named, not just any" do
      create(:qualification)
      chosen = create(:qualification)

      post worker_worker_qualifications_url(worker),
        params: { worker_qualification: { qualification_id: chosen.id } }

      expect(worker.reload.qualifications).to contain_exactly(chosen)
    end

    it "rejects a request without a qualification_id" do
      post worker_worker_qualifications_url(worker), params: { worker_qualification: { other: 1 } }

      expect(response).to have_http_status(:bad_request)
    end

    it "only affects the worker in the URL" do
      other = create(:worker)

      post worker_worker_qualifications_url(worker),
        params: { worker_qualification: { qualification_id: qualification.id, worker_id: other.id } }

      expect(other.reload.qualifications).to be_empty
      expect(worker.reload.qualifications).to contain_exactly(qualification)
    end

    it "refuses a qualification the worker already holds" do
      worker.qualifications << qualification

      expect {
        post worker_worker_qualifications_url(worker),
          params: { worker_qualification: { qualification_id: qualification.id } }
      }.not_to change(WorkerQualification, :count)

      expect(response).to redirect_to(worker_path(worker))
      expect(flash[:error]).to eq("Could not add qualification: Qualification has already been taken.")
    end

    it "refuses a nonexistent qualification" do
      post worker_worker_qualifications_url(worker),
        params: { worker_qualification: { qualification_id: 999_999 } }

      expect(worker.reload.qualifications).to be_empty
      expect(flash[:error]).to eq("Could not add qualification: Qualification must exist.")
    end

    it "returns not found for an unknown worker" do
      post worker_worker_qualifications_url(worker_id: 999_999),
        params: { worker_qualification: { qualification_id: qualification.id } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /workers/:worker_id/worker_qualifications/:id" do
    it "removes the qualification from the worker and redirects back" do
      worker.qualifications << qualification
      wq = worker.worker_qualifications.first

      delete worker_worker_qualification_url(worker, wq)

      expect(worker.reload.qualifications).to be_empty
      expect(Qualification.exists?(qualification.id)).to be(true)
      expect(response).to redirect_to(worker_path(worker))
      expect(flash[:notice]).to eq("Removed Fire Watch.")
    end

    it "removes only the qualification named" do
      kept = create(:qualification)
      worker.qualifications << [ kept, qualification ]

      delete worker_worker_qualification_url(worker, worker.worker_qualifications.find_by!(qualification: qualification))

      expect(worker.reload.qualifications).to contain_exactly(kept)
    end

    it "will not remove another worker's qualification" do
      other = create(:worker, qualifications: [ qualification ])
      wq = other.worker_qualifications.first

      delete worker_worker_qualification_url(worker, wq)

      expect(response).to have_http_status(:not_found)
      expect(other.reload.qualifications).to contain_exactly(qualification)
    end
  end
end
