module Admin
  class ImagesController < BaseController
    MAX_IMAGE_SIZE = 5.megabytes
    ALLOWED_IMAGE_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze

    def create
      uploaded_image = params.require(:image)

      unless uploaded_image.content_type.in?(ALLOWED_IMAGE_TYPES)
        return render json: { error: "Unsupported image type." }, status: :unprocessable_entity
      end

      if uploaded_image.size > MAX_IMAGE_SIZE
        return render json: { error: "Image must be smaller than 5 MB." }, status: :unprocessable_entity
      end

      blob = ActiveStorage::Blob.create_and_upload!(
        io: uploaded_image.open,
        filename: uploaded_image.original_filename,
        content_type: uploaded_image.content_type
      )

      render json: {
        markdown: "![#{blob.filename.base}](#{rails_blob_path(blob, only_path: true)})"
      }, status: :created
    end
  end
end
