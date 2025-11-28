json.array! @validation_results do |result|
  json.circle_code result[:circle_code]
  json.circle_value result[:circle_value]
  json.label result[:label]
  json.value result[:value]
  json.valid result[:valid]

  if result[:errors]
    json.errors result[:errors]
  end
end
