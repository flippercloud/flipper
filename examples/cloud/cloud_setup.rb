if ENV["FLIPPER_CLOUD_TOKEN"].nil? || ENV["FLIPPER_CLOUD_TOKEN"].empty?
  warn "FLIPPER_CLOUD_TOKEN missing so skipping cloud example."
  exit
end

matrix_key = if ENV["CI"]
  suffix_rails = ENV["RAILS_VERSION"].split(".").take(2).join
  suffix_ruby = RUBY_VERSION.split(".").take(2).join
  "FLIPPER_CLOUD_TOKEN_#{suffix_ruby}_#{suffix_rails}"
else
  "FLIPPER_CLOUD_TOKEN"
end

if matrix_token = ENV[matrix_key]
  puts "Using #{matrix_key} for FLIPPER_CLOUD_TOKEN"
  ENV["FLIPPER_CLOUD_TOKEN"] = matrix_token
else
  warn "Missing #{matrix_key}. Go create an environment in flipper cloud and set #{matrix_key} to the adapter token for that environment in github actions secrets."
  exit 1
end
