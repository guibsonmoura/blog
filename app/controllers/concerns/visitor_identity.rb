# Shared identity for "one per visitor" toggles (post reactions, comment likes).
# A visitor is their signed-in Reader when present, otherwise the durable
# anonymous session cookie (reader_id).
module VisitorIdentity
  extend ActiveSupport::Concern

  private

  # Attributes used to create a record owned by the current visitor.
  def visitor_scope
    reader_signed_in? ? { reader: current_reader } : { session_id: reader_id }
  end

  # The current visitor's existing record within the given association, if any.
  def visitor_record(relation)
    if reader_signed_in?
      relation.find_by(reader_id: current_reader.id)
    else
      relation.find_by(reader_id: nil, session_id: reader_id)
    end
  end
end
