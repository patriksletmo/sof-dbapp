require 'test_helper'

class FunkisApplicationCreationTest < AuthenticatedIntegrationTest
  test 'create funkis application' do
    post '/api/v1/funkis_application', headers: auth_headers, params: {
        item: {
            ssn: '900101-0101',
            phone: '013176800',
            tshirt_size: 'Female XS',
            allergies: 'Jordnötter',
            drivers_license: true,
            presale_choice: FunkisApplication::PRESALE_NONE
        }
    }

    assert_response :redirect
    item_url = redirected_url

    get item_url, headers: auth_headers
    application = JSON.parse response.body

    assert_equal '900101-0101',                   application['ssn']
    assert_equal '013176800',                     application['phone']
    assert_equal 'Female XS',                     application['tshirt_size']
    assert_equal 'Jordnötter',                    application['allergies']
    assert_equal true,                            application['drivers_license']
    assert_equal FunkisApplication::PRESALE_NONE, application['presale_choice']

    put item_url, headers: auth_headers, params: {
        item: {
            funkis_shift_applications_attributes: [
                {
                    funkis_shift_id: funkis_shifts(:one).id
                },
                {
                    funkis_shift_id: funkis_shifts(:four).id
                }
            ]
        }
    }

    assert_response :redirect

    get redirected_url, headers: auth_headers
    application = JSON.parse response.body

    assert_equal 'Thursday', application['funkis_shift_applications'][0]['funkis_shift']['day']
    assert_equal 'Friday',  application['funkis_shift_applications'][1]['funkis_shift']['day']

    # Remove one shift, keep the shift with limit=1
    put item_url, headers: auth_headers, params: {
        item: {
            funkis_shift_applications_attributes: [
                {
                    iter: 1,
                    id: application['funkis_shift_applications'][0]['id'],
                    _destroy: 1
                },
                {
                    iter: 1,
                    id: application['funkis_shift_applications'][1]['id'],
                    _destroy: 1
                },
                {
                    iter: 1,
                    'funkis_shift_id': funkis_shifts(:four).id
                }
            ]
        }
    }

    assert_response :redirect

    get redirected_url, headers: auth_headers
    application = JSON.parse response.body

    assert_equal 1, application['funkis_shift_applications'].count
    assert_equal 'Friday', application['funkis_shift_applications'][0]['funkis_shift']['day']

    put item_url, headers: auth_headers, params: {
        item: {
            terms_agreed: true
        }
    }

    assert_response :redirect

    get redirected_url, headers: auth_headers
    application = JSON.parse response.body

    # Terms should be agreed
    assert application['terms_agreed_at'] <= DateTime.now

    # Verify that a confirmation e-mail was sent
    mail = ActionMailer::Base.deliveries.last
    assert_equal 'no-reply@sof17.se', mail['from'].to_s
    assert_equal 'test@sof17.se',     mail['to'].to_s

    put item_url, headers: auth_headers, params: {
        item: {
            ssn: '990101-9999'
        }
    }

    # Further updates should not be accepted
    assert_response :bad_request
  end
end