module.exports = class EryStatus
  @success:  "success"
  @failure:  "failure"
  @missing:  "missing"

  @validStatus: (status) -> status?.match /^(success|failure|missing)/
