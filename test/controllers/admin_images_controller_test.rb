require "test_helper"

class AdminImagesControllerTest < ActionDispatch::IntegrationTest
  test "redirects anonymous users to login" do
    post admin_images_path

    assert_redirected_to superadmin_login_path
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

  test "uploaded image markdown uses proxied url, not direct minio url" do
    sign_in_as users(:admin)

    post admin_images_path, params: {
      image: fixture_file_upload("test-image.png", "image/png")
    }

    markdown = JSON.parse(response.body).fetch("markdown")
    assert_no_match "minio", markdown
    assert_no_match "9000", markdown
  end

  test "admin cannot upload unsupported file types" do
    sign_in_as users(:admin)

    post admin_images_path, params: {
      image: fixture_file_upload("test-image.png", "text/plain")
    }

    assert_response :unprocessable_entity
  end
end
