require "test_helper"

class AdminImagesControllerTest < ActionDispatch::IntegrationTest
  test "redirects anonymous users" do
    post admin_images_path

    assert_redirected_to new_admin_session_path
  end

  test "admin can upload an inline image" do
    sign_in_as users(:admin)

    assert_difference "ActiveStorage::Blob.count", 1 do
      post admin_images_path, params: {
        image: fixture_file_upload("test-image.png", "image/png")
      }
    end

    assert_response :created
    assert_match "/rails/active_storage/", JSON.parse(response.body).fetch("markdown")
  end

  test "admin cannot upload unsupported files" do
    sign_in_as users(:admin)

    post admin_images_path, params: {
      image: fixture_file_upload("test-image.png", "text/plain")
    }

    assert_response :unprocessable_entity
  end
end
