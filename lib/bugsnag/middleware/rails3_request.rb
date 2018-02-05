module Bugsnag::Middleware
  class Rails3Request
    SPOOF = "[SPOOF]".freeze

    ##
    # Extracts and attaches rails data to the request.
    def initialize(bugsnag)
      @bugsnag = bugsnag
    end

    ##
    # Executes the callback.
    def call(report)
      if report.request_data[:rack_env]
        env = report.request_data[:rack_env]
        params = env["action_dispatch.request.parameters"]
        client_ip = env["action_dispatch.remote_ip"].to_s rescue SPOOF

        if params
          # Set the context
          report.context = "#{params[:controller]}##{params[:action]}"

          # Augment the request tab
          report.add_tab(:request, {
            :railsAction => "#{params[:controller]}##{params[:action]}",
            :params => params
          })
        end

        # Use action_dispatch.remote_ip for IP address fields and send request id
        report.add_tab(:request, {
          :clientIp => client_ip,
          :requestId => env["action_dispatch.request_id"]
        })

        report.user["id"] = client_ip

        # Add the rails version
        if report.configuration.send_environment
          report.add_tab(:environment, {
            :railsVersion => Rails::VERSION::STRING
          })
        end
      end

      @bugsnag.call(report)
    end
  end
end
