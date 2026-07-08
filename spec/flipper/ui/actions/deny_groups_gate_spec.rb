RSpec.describe Flipper::UI::Actions::DenyGroupsGate do
  let(:token) do
    if Rack::Protection::AuthenticityToken.respond_to?(:random_token)
      Rack::Protection::AuthenticityToken.random_token
    else
      'a'
    end
  end

  let(:session) do
    { :csrf => token, 'csrf' => token, '_csrf_token' => token }
  end

  describe 'POST /features/:feature/deny_groups' do
    let(:group_name) { 'admins' }

    before do
      Flipper.register(:admins, &:admin?)
    end

    after do
      Flipper.unregister_groups
    end

    context 'denying a group' do
      before do
        post 'features/search/deny_groups',
             { 'value' => group_name, 'operation' => 'deny', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'adds item to denied groups' do
        expect(flipper[:search].deny_groups_value).to include('admins')
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end

      context 'feature name contains space' do
        before do
          post 'features/sp+ace/deny_groups',
               { 'value' => group_name, 'operation' => 'deny', 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'adds item to denied groups' do
          expect(flipper["sp ace"].deny_groups_value).to include('admins')
        end

        it 'redirects back to feature' do
          expect(last_response.status).to be(302)
          expect(last_response.headers['location']).to eq('/features/sp+ace')
        end
      end

      context 'group name contains whitespace' do
        let(:group_name) { '  admins  ' }

        it 'adds item without whitespace' do
          expect(flipper[:search].deny_groups_value).to include('admins')
        end
      end

      context 'for an unregistered group' do
        context 'unknown group name' do
          let(:group_name) { 'not_here' }

          it 'redirects back with error' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['location']).to eq('/features/search/deny_groups?error=The+group+named+%22not_here%22+has+not+been+registered.')
          end
        end

        context 'empty group name' do
          let(:group_name) { '' }

          it 'redirects back with error' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['location']).to eq('/features/search/deny_groups?error=The+group+named+%22%22+has+not+been+registered.')
          end
        end

        context 'nil group name' do
          let(:group_name) { nil }

          it 'redirects back with error' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['location']).to eq('/features/search/deny_groups?error=The+group+named+%22%22+has+not+been+registered.')
          end
        end
      end
    end

    context 'permitting a group' do
      let(:group_name) { 'admins' }

      before do
        flipper[:search].deny_group :admins
        post 'features/search/deny_groups',
             { 'value' => group_name, 'operation' => 'permit', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'removes item from denied groups' do
        expect(flipper[:search].deny_groups_value).not_to include('admins')
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end

      context 'group name contains whitespace' do
        let(:group_name) { '  admins  ' }

        it 'removes item without whitespace' do
          expect(flipper[:search].deny_groups_value).not_to include('admins')
        end
      end
    end
  end
end
