RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_have_enqueued_mail, :have_enqueued_mail
RSpec::Matchers.define_negated_matcher :not_have_enqueued_job, :have_enqueued_job
