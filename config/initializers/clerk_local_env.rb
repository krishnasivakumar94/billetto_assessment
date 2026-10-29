if Rails.env.development?
  local_env_values = {}
  [Rails.root.join(".env"), Rails.root.join(".env.clerk")].each do |local_env|
    next unless local_env.file?

    local_env.read.scan(/^([A-Z_]+)=(?:'([^']*)'|"([^"]*)"|([^\r\n#]*))/m).each do |key, single_quoted, double_quoted, unquoted|
      local_env_values[key] = single_quoted || double_quoted || unquoted&.strip
    end
  end

  %w[CLERK_PUBLISHABLE_KEY CLERK_JWT_KEY CLERK_ISSUER CLERK_AUTHORIZED_PARTIES BILLETTO_API_KEYPAIR BILLETTO_PUBLIC_EVENTS_URL].each do |key|
    ENV[key] ||= local_env_values[key] if local_env_values[key]
  end
end
