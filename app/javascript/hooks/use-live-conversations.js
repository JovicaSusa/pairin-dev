import { router } from "@inertiajs/react";
import { createConsumer } from "@rails/actioncable";
import { useEffect } from "react";

const consumer = createConsumer();

// The server only signals that a conversation changed. The page then asks for
// fresh props through the normal, permission-checked request, so nothing is
// ever trusted from the socket and missed signals are simply caught up on.
function refresh() {
  const path = window.location.pathname;
  const only = ["unreadMessages"];
  if (path.startsWith("/conversations")) only.push("conversations", "conversation");
  if (path.startsWith("/partners")) only.push("partnership", "partnerships");

  router.reload({
    only,
    async: true,
  });
}

export function useLiveConversations(userId) {
  useEffect(() => {
    if (!userId) return undefined;

    let connectedBefore = false;
    let missedWhileHidden = false;

    // A hidden tab doesn't refresh: opening a thread marks it read, and nobody
    // has read it yet.
    const refreshIfVisible = () => {
      if (document.hidden) {
        missedWhileHidden = true;
      } else {
        refresh();
      }
    };

    const subscription = consumer.subscriptions.create("ConversationsChannel", {
      // After a dropped connection, catch up on whatever was missed.
      connected() {
        if (connectedBefore) refreshIfVisible();
        connectedBefore = true;
      },
      received: refreshIfVisible,
    });

    const onVisibilityChange = () => {
      if (!document.hidden && missedWhileHidden) {
        missedWhileHidden = false;
        refresh();
      }
    };
    document.addEventListener("visibilitychange", onVisibilityChange);

    return () => {
      document.removeEventListener("visibilitychange", onVisibilityChange);
      subscription.unsubscribe();
    };
  }, [userId]);
}
