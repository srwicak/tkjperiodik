// Import all the channels to be used by Action Cable
//import "./user_verification_channel"

import consumer from "channels/consumer"

// Function to subscribe to a specific channel
function subscribeToChannel(channelName, params, callbacks) {
  return consumer.subscriptions.create(
    { channel: channelName, ...params },
    {
      connected() {
        //console.log(`${channelName} connected`);
      },

      disconnected() {
        //console.log(`${channelName} disconnected`);
      },

      received(data) {
        callbacks.received(data);
      }
    }
  );
}
// Function to unsubscribe from a specific channel
function unsubscribeFromChannel(subscription) {
  if (subscription) {
    //console.log("Unsubscribing from channel:", subscription.identifier);
    subscription.unsubscribe();
  } else {
    //console.log("No subscription to unsubscribe.");
  }
}
let userVerificationSubscription

function subscribeBasedOnPath() {
  // Subscribe to channels based on path
  const path = window.location.pathname
  //console.log(path)
  
  if (path.includes('/kelola/pengguna/verifikasi')) {
    userVerificationSubscription = subscribeToChannel('UserVerificationChannel', { data_id: 'data_id_value' }, {
      received: (data) => {
        //let table = Tabulator.findTable("#data")

        if (data.action === "reviewer_add") {
          let row = table.getRow(data.user_id)
          if (row) {
            row.update({ peninjau: data.reviewer });
          }
        }

        if (data.action === "verification_update" || data.action === "reviewer_remove") {
          table.setData()
        }
        
        //console.log('User verification data:', data);
      }
    })
  }
}
// Unsubscribe when leaving the page
function unsubscribeAll() {
  if (userVerificationSubscription) {
    unsubscribeFromChannel(userVerificationSubscription);
    userVerificationSubscription = null;
  }
  // Uncomment these lines if you want to unsubscribe others
  // unsubscribeFromChannel(documentUploadSubscription);
}

document.addEventListener('turbo:load', () => {
  unsubscribeAll()
  subscribeBasedOnPath()
});
