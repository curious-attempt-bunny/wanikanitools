require 'new_relic/agent/method_tracer'

JSON.class_eval do
  include ::NewRelic::Agent::MethodTracer

  add_method_tracer :parse
end

File.class_eval do
  include ::NewRelic::Agent::MethodTracer

  add_method_tracer :read
end