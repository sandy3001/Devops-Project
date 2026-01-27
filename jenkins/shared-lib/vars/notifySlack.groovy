def call(String status, String message) {
    slackSend(
        channel: env.SLACK_CHANNEL,
        color: status == "SUCCESS" ? "good" : "danger",
        message: "${status}: ${message}"
    )
}
