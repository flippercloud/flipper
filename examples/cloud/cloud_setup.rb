if ENV["FLIPPER_CLOUD_TOKEN"].nil? || ENV["FLIPPER_CLOUD_TOKEN"].empty?
  warn "FLIPPER_CLOUD_TOKEN missing so skipping cloud example."
  exit
end
