import consumer from "channels/consumer"

consumer.subscriptions.create("UserVerificationChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    //console.log("Connected to UserVerificationChannel")
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
    //console.log("Disconnected from UserVerificationChannel")
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
  }
});
