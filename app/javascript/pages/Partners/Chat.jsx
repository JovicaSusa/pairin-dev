import { useEffect, useRef } from "react";
import { Lock } from "lucide-react";
import { Composer, Messages } from "@/components/ConversationParts";
import WorkspaceFrame from "@/components/WorkspaceFrame";

// The Workspace chat, on a page of its own. Opening it marks the messages read.
export default function Chat({ partnership }) {
  const conversation = partnership.conversation;
  const scroller = useRef(null);

  useEffect(() => {
    if (scroller.current) scroller.current.scrollTop = scroller.current.scrollHeight;
  }, [conversation.messages.length]);

  return (
    <WorkspaceFrame
      partnership={partnership}
      title={`Chat with ${conversation.other.name}`}
      back={{ href: `/partners/${partnership.id}`, label: "Overview" }}
    >
      <div className="flex h-[calc(100dvh-11rem)] min-h-[20rem] flex-col rounded-2xl border-2 border-black bg-white p-3 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] md:h-[70vh] md:p-4">
        <div ref={scroller} className="min-h-0 flex-1 overflow-y-auto">
          <Messages messages={conversation.messages} dim={partnership.ended} />
        </div>
        <div className="pt-3">
          {conversation.can_send ? (
            <Composer conversation={conversation} />
          ) : (
            <div className="flex items-start gap-2 rounded-xl border-2 border-black bg-black/5 p-3 text-sm">
              <Lock className="mt-0.5 h-4 w-4 shrink-0" />
              <b>{partnership.ended_by_viewer ? "You ended this partnership." : "This partnership has ended."} You can still read it.</b>
            </div>
          )}
        </div>
      </div>
    </WorkspaceFrame>
  );
}
