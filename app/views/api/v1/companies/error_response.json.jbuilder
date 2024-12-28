# RFC 7807
json.title @title
json.status @status
if @company
  json.detail @company.errors.full_messages.join(", ")
  json.errors @company.errors
end
