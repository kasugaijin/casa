require "rails_helper"

RSpec.describe "CasaOrg", type: :request do
  let(:casa_org) { build(:casa_org) }
  let(:casa_case) { build_stubbed(:casa_case, casa_org: casa_org) }

  before {
    stub_twillio
    sign_in create(:casa_admin, casa_org: casa_org)
  }

  describe "GET /edit" do
    subject(:request) do
      get edit_casa_org_url(casa_org)

      response
    end

    it { is_expected.to be_successful }
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:attributes) do
        {
          name: "name", display_name: "display_name", address: "address",
          twilio_account_sid: "articuno34", twilio_api_key_sid: "Aladdin",
          twilio_api_key_secret: "open sesame", twilio_phone_number: "+12223334444"
        }
      end

      subject(:request) do
        patch casa_org_url(casa_org), params: {casa_org: attributes}

        response
      end

      it "updates the requested casa_org" do
        request
        expect(casa_org.reload.name).to eq "name"
        expect(casa_org.display_name).to eq "display_name"
        expect(casa_org.address).to eq "address"
        expect(casa_org.twilio_phone_number).to eq "+12223334444"
      end

      describe "on logo update" do
        let(:logo) { upload_file("#{Rails.root}/spec/fixtures/company_logo.png") }

        subject(:request) do
          patch casa_org_url(casa_org), params: params

          response
        end

        context "with a new logo" do
          let(:params) { {casa_org: {logo: logo}} }

          it "uploads the company logo" do
            expect { request }.to change(ActiveStorage::Attachment, :count).by(1)
          end
        end

        context "with no logo" do
          let(:params) { {casa_org: {name: "name"}} }

          it "does not revert logo to default" do
            casa_org.update(logo: logo)

            expect { request }.not_to change(ActiveStorage::Attachment, :count)
          end
        end
      end

      context "and html format" do
        it { is_expected.to redirect_to(edit_casa_org_url) }

        it "shows the correct flash message" do
          request
          expect(flash[:notice]).to eq("CASA organization was successfully updated.")
        end
      end

      context "and json format" do
        subject(:request) do
          patch casa_org_url(casa_org, format: :json), params: {casa_org: attributes}

          response
        end

        it { is_expected.to have_http_status(:ok) }

        it "returns correct payload", :aggregate_failures do
          response_data = request.body
          expect(response_data).to match("display_name".to_json)
        end
      end
    end

    context "with invalid parameters" do
      let(:params) { {casa_org: {name: nil}} }

      subject(:request) do
        patch casa_org_url(casa_org), params: params

        response
      end

      it "does not update the requested casa_org" do
        expect { request }.not_to change { casa_org.reload.name }
      end

      context "and html format" do
        it { is_expected.to be_successful }

        it "renders the edit template" do
          expect(request.body).to match(/error_explanation/)
        end
      end

      context "and json format" do
        subject(:request) do
          patch casa_org_url(casa_org, format: :json), params: params

          response
        end

        it { is_expected.to have_http_status(:unprocessable_entity) }

        it "returns correct payload" do
          response_data = request.body
          expect(response_data).to match("Name can't be blank".to_json)
        end
      end
    end
  end
end

def stub_twillio
  twillio_client = instance_double(Twilio::REST::Client)
  messages = instance_double(Twilio::REST::Api::V2010::AccountContext::MessageList)
  allow(Twilio::REST::Client).to receive(:new).with("Aladdin", "open sesame", "articuno34").and_return(twillio_client)
  allow(twillio_client).to receive(:messages).and_return(messages)
  allow(messages).to receive(:list).and_return([])
end
